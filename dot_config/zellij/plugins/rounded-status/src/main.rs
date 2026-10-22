//! Native status-bar key discovery with rounded, mode-dependent hints.
//! A background controller opens a non-focusable pinned strip only when needed.
//! Closing the strip leaves neither a tiled pane nor an empty status row.
mod hints;

use ansi_term::{Colour::Fixed, Style};
use std::collections::BTreeMap;
use unicode_width::UnicodeWidthStr;
use zellij_tile::prelude::*;

#[cfg(test)]
use test_host::{
    change_floating_panes_coordinates, close_self, pipe_message_to_plugin, set_selectable,
};

const HALF_CIRCLE: &str = "\u{e0b4}";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Placement {
    position: usize,
    tab_id: usize,
    rows: usize,
    cols: usize,
}

impl Placement {
    fn coordinates(self) -> FloatingPaneCoordinates {
        FloatingPaneCoordinates::new(
            Some("0".into()),
            Some(self.rows.saturating_sub(2).to_string()),
            Some(self.cols.max(1).to_string()),
            Some("1".into()),
            Some(true),
            Some(true),
        )
        .unwrap()
    }
}

#[derive(Default)]
struct State {
    is_strip: bool,
    strip_tab_id: usize,
    permitted: bool,
    have_mode: bool,
    own_id: u32,
    mode: ModeInfo,
    keybinds: KeybindsVec,
    placement: Option<Placement>,
    announced: Option<Placement>,
    closing: bool,
    epoch: u64,
}

register_plugin!(State);

fn should_show(mode: InputMode) -> bool {
    !matches!(mode, InputMode::Normal | InputMode::Tmux)
}

// Keep these ANSI colors in sync with layouts/tmux.kdl's mode_* entries.
fn mode_style(mode: InputMode) -> (&'static str, u8) {
    match mode {
        InputMode::Normal => ("NORMAL", 4),
        InputMode::Tmux => ("TMUX", 3),
        InputMode::Locked => ("LOCKED", 1),
        InputMode::Pane => ("PANE", 2),
        InputMode::Tab => ("TAB", 6),
        InputMode::Resize => ("RESIZE", 5),
        InputMode::Move => ("MOVE", 9),
        InputMode::Scroll => ("SCROLL", 12),
        InputMode::EnterSearch => ("SEARCH INPUT", 11),
        InputMode::Search => ("SEARCH", 13),
        InputMode::RenameTab => ("RENAME TAB", 14),
        InputMode::RenamePane => ("RENAME PANE", 10),
        InputMode::Session => ("SESSION", 7),
        InputMode::Prompt => ("PROMPT", 15),
    }
}

impl ZellijPlugin for State {
    fn load(&mut self, config: BTreeMap<String, String>) {
        self.is_strip = config.get("role").map(String::as_str) == Some("strip");
        self.strip_tab_id = config
            .get("tab_id")
            .and_then(|s| s.parse().ok())
            .unwrap_or(0);
        self.own_id = get_plugin_ids().plugin_id;
        subscribe(&[
            EventType::PermissionRequestResult,
            EventType::ModeUpdate,
            EventType::InitialKeybinds,
            EventType::TabUpdate,
        ]);
        // Leave the permission dialog selectable until the user answers it.
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
            PermissionType::MessageAndLaunchOtherPlugins,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                self.permitted = true;
                set_selectable(false);
            }
            Event::PermissionRequestResult(PermissionStatus::Denied) => {
                self.closing = true;
                close_self();
                return false;
            }
            Event::InitialKeybinds(keybinds) => {
                self.keybinds = keybinds;
                self.mode.keybinds = self.keybinds.clone();
            }
            Event::ModeUpdate(mut mode) => {
                if mode.keybinds.is_empty() {
                    mode.keybinds = self.keybinds.clone();
                } else {
                    self.keybinds = mode.keybinds.clone();
                }
                self.mode = mode;
                self.have_mode = true;
            }
            Event::TabUpdate(tabs) => {
                self.placement = tabs.iter().find(|t| t.active).map(|t| Placement {
                    position: t.position,
                    tab_id: t.tab_id,
                    rows: t.display_area_rows,
                    cols: t.display_area_columns,
                });
            }
            _ => {}
        }
        self.sync_visibility();
        self.permitted && self.is_strip && !self.closing
    }

    fn pipe(&mut self, message: PipeMessage) -> bool {
        if self.is_strip && self.permitted && message.name == "place" {
            if let Some(place) = self.placement {
                change_floating_panes_coordinates(vec![(
                    PaneId::Plugin(self.own_id),
                    place.coordinates(),
                )]);
            }
        }
        self.is_strip && !self.closing
    }

    fn render(&mut self, _rows: usize, cols: usize) {
        if self.permitted && self.is_strip && self.have_mode && !self.closing {
            print!("{}\x1b[0m\x1b[48;5;0m\x1b[K", render_line(&self.mode, cols));
        }
    }
}

impl State {
    fn sync_visibility(&mut self) {
        if !self.permitted || !self.have_mode || self.closing {
            return;
        }
        let visible = should_show(self.mode.mode);
        if self.is_strip {
            let other_tab = self
                .placement
                .map(|p| p.tab_id != self.strip_tab_id)
                .unwrap_or(false);
            if !visible || other_tab {
                self.closing = true;
                close_self();
            } else if self.placement != self.announced {
                if let Some(place) = self.placement {
                    self.announced = Some(place);
                    change_floating_panes_coordinates(vec![(
                        PaneId::Plugin(self.own_id),
                        place.coordinates(),
                    )]);
                }
            }
        } else if !visible {
            self.announced = None;
        } else if self.placement != self.announced {
            if let Some(place) = self.placement {
                if self.announced.map(|old| old.tab_id) != Some(place.tab_id) {
                    self.epoch += 1;
                }
                self.announced = Some(place);
                let config = BTreeMap::from([
                    ("role".into(), "strip".into()),
                    ("tab_id".into(), place.tab_id.to_string()),
                    ("epoch".into(), self.epoch.to_string()),
                ]);
                // No should_focus flag: message-launched panes default to no focus.
                // No suppress/unsuppress cycle: the host otherwise re-focuses floats.
                pipe_message_to_plugin(
                    MessageToPlugin::new("place")
                        .with_plugin_url("zellij:OWN_URL")
                        .with_plugin_config(config)
                        .with_floating_pane_coordinates(place.coordinates())
                        .new_plugin_instance_should_float(true)
                        .new_plugin_instance_should_have_pane_title("Mode shortcuts"),
                );
            }
        }
    }
}

fn segment(text: &str, color: u8, first: bool) -> String {
    let prefix = if first {
        String::new()
    } else {
        Style::new()
            .fg(Fixed(0))
            .on(Fixed(color))
            .paint(HALF_CIRCLE)
            .to_string()
    };
    format!(
        "{}{}{} ",
        prefix,
        Style::new()
            .fg(Fixed(0))
            .on(Fixed(color))
            .paint(format!(" {} ", text)),
        Style::new()
            .fg(Fixed(color))
            .on(Fixed(0))
            .paint(HALF_CIRCLE)
    )
}

fn width(text: &str, first: bool) -> usize {
    UnicodeWidthStr::width(text) + 4 + usize::from(!first)
}

fn render_line(mode: &ModeInfo, cols: usize) -> String {
    if !should_show(mode.mode) {
        return String::new();
    }
    let (name, color) = mode_style(mode.mode);
    if width(name, true) > cols {
        return String::new();
    }
    let mut output = segment(name, color, true);
    let mut used = width(name, true);
    let mut hints = hints::get_keys_and_hints(mode);
    if mode.mode == InputMode::Locked {
        hints.push((
            "Unlock".into(),
            "Unlock".into(),
            hints::action_key(
                &mode.get_mode_keybinds(),
                &[actions::Action::SwitchToMode {
                    input_mode: InputMode::Normal,
                }],
            ),
        ));
    }
    for (long, short, keys) in hints {
        if keys.is_empty() {
            continue;
        }
        let keys = keys
            .iter()
            .map(ToString::to_string)
            .collect::<Vec<_>>()
            .join("|");
        let full = format!("{} {}", keys, long);
        let brief = format!("{} {}", keys, short);
        let text = if used + width(&full, false) <= cols {
            full
        } else {
            brief
        };
        if used + width(&text, false) + 1 > cols {
            if used < cols {
                output.push('…');
            }
            break;
        }
        used += width(&text, false);
        output.push_str(&segment(&text, 4, false));
    }
    output
}

#[cfg(test)]
mod tests {
    use super::*;
    fn plain(s: &str) -> String {
        let mut escaped = false;
        s.chars()
            .filter(|c| {
                if *c == '\x1b' {
                    escaped = true;
                    false
                } else if escaped {
                    if *c == 'm' {
                        escaped = false;
                    }
                    false
                } else {
                    true
                }
            })
            .collect()
    }

    #[test]
    fn normal_and_tmux_are_hidden_but_every_other_mode_is_visible() {
        assert!(!should_show(InputMode::Normal));
        assert!(!should_show(InputMode::Tmux));
        for mode in [
            InputMode::Locked,
            InputMode::Pane,
            InputMode::Tab,
            InputMode::Resize,
            InputMode::Move,
            InputMode::Scroll,
            InputMode::EnterSearch,
            InputMode::Search,
            InputMode::RenamePane,
            InputMode::RenameTab,
            InputMode::Session,
            InputMode::Prompt,
        ] {
            assert!(should_show(mode));
        }
    }

    #[test]
    fn first_segment_has_flat_left_edge_and_other_segments_are_scooped() {
        assert_eq!(plain(&segment("PANE", 2, true)), " PANE  ");
        assert_eq!(plain(&segment("n New", 4, false)), " n New  ");
    }

    #[test]
    fn all_mode_colors_are_distinct() {
        let modes = [
            InputMode::Normal,
            InputMode::Tmux,
            InputMode::Locked,
            InputMode::Pane,
            InputMode::Tab,
            InputMode::Resize,
            InputMode::Move,
            InputMode::Scroll,
            InputMode::EnterSearch,
            InputMode::Search,
            InputMode::RenameTab,
            InputMode::RenamePane,
            InputMode::Session,
            InputMode::Prompt,
        ];
        let colors: std::collections::BTreeSet<_> =
            modes.iter().map(|m| mode_style(*m).1).collect();
        assert_eq!(colors.len(), modes.len());
    }

    #[test]
    fn hints_use_effective_keymap_and_fit_narrow_terminals() {
        let mut mode = ModeInfo::default();
        mode.mode = InputMode::Pane;
        mode.keybinds = vec![(
            InputMode::Pane,
            vec![(
                KeyWithModifier::new(BareKey::Char('v')),
                vec![
                    actions::Action::CloseFocus,
                    actions::Action::SwitchToMode {
                        input_mode: InputMode::Normal,
                    },
                ],
            )],
        )];
        let line = plain(&render_line(&mode, 100));
        assert!(line.contains("v Close"));
        assert!(!line.contains("x Close"));
        for cols in 0..=100 {
            assert!(UnicodeWidthStr::width(plain(&render_line(&mode, cols)).as_str()) <= cols);
        }
    }

    #[test]
    fn overlay_is_pinned_borderless_one_row_above_the_bottom_bar() {
        let coords = Placement {
            position: 0,
            tab_id: 7,
            rows: 40,
            cols: 120,
        }
        .coordinates();
        assert_eq!(coords.y, Some("38".parse().unwrap()));
        assert_eq!(coords.height, Some("1".parse().unwrap()));
        assert_eq!(coords.pinned, Some(true));
        assert_eq!(coords.borderless, Some(true));
    }

    fn tab(position: usize, tab_id: usize, rows: usize, cols: usize) -> Event {
        Event::TabUpdate(vec![TabInfo {
            active: true,
            position,
            tab_id,
            display_area_rows: rows,
            display_area_columns: cols,
            ..Default::default()
        }])
    }

    fn mode(input: InputMode) -> Event {
        Event::ModeUpdate(ModeInfo {
            mode: input,
            ..Default::default()
        })
    }

    #[test]
    fn controller_launches_only_outside_normal_and_tmux_and_never_requests_focus() {
        test_host::clear();
        let mut controller = State {
            permitted: true,
            ..Default::default()
        };
        controller.update(tab(0, 7, 40, 120));
        controller.update(mode(InputMode::Normal));
        controller.update(mode(InputMode::Tmux));
        assert!(test_host::take().is_empty());
        controller.update(mode(InputMode::Pane));
        let first = test_host::launch();
        assert_eq!(first.plugin_config.get("role").unwrap(), "strip");
        assert_ne!(
            first.new_plugin_args.as_ref().unwrap().should_focus,
            Some(true)
        );
        assert_eq!(
            first.floating_pane_coordinates.unwrap().height,
            Some("1".parse().unwrap())
        );
        controller.update(mode(InputMode::Search));
        assert!(test_host::take().is_empty());
        controller.update(mode(InputMode::Normal));
        controller.update(mode(InputMode::Pane));
        let second = test_host::launch();
        assert_ne!(
            first.plugin_config.get("epoch"),
            second.plugin_config.get("epoch")
        );
    }

    #[test]
    fn strip_closes_without_leaving_a_tiled_or_suppressed_pane() {
        for hidden in [InputMode::Normal, InputMode::Tmux] {
            test_host::clear();
            let mut strip = State {
                permitted: true,
                is_strip: true,
                strip_tab_id: 7,
                ..Default::default()
            };
            strip.update(tab(0, 7, 40, 120));
            strip.update(mode(InputMode::Pane));
            test_host::clear();
            strip.update(mode(hidden));
            assert!(strip.closing);
            assert_eq!(test_host::take().len(), 1);
        }
    }

    #[test]
    fn strip_tracks_resize_and_closes_when_the_user_changes_tab() {
        test_host::clear();
        let mut strip = State {
            permitted: true,
            is_strip: true,
            strip_tab_id: 7,
            have_mode: true,
            mode: ModeInfo {
                mode: InputMode::Pane,
                ..Default::default()
            },
            ..Default::default()
        };
        strip.update(tab(0, 7, 40, 120));
        assert!(!strip.closing);
        test_host::clear();
        strip.update(tab(0, 7, 25, 80));
        let commands = test_host::take();
        match &commands[0] {
            test_host::Command::Position(coords) => {
                assert_eq!(coords[0].1.width, Some("80".parse().unwrap()));
                assert_eq!(coords[0].1.y, Some("23".parse().unwrap()));
            }
            _ => panic!("expected updated position"),
        }
        strip.update(tab(1, 42, 25, 80));
        assert!(strip.closing);
        assert_eq!(test_host::take().len(), 1);
    }
}

#[cfg(test)]
mod test_host {
    use super::*;
    #[derive(Debug)]
    pub enum Command {
        Close,
        Position(Vec<(PaneId, FloatingPaneCoordinates)>),
        Launch(MessageToPlugin),
    }
    thread_local! { static COMMANDS: std::cell::RefCell<Vec<Command>> = const { std::cell::RefCell::new(Vec::new()) }; }
    pub fn close_self() {
        COMMANDS.with(|c| c.borrow_mut().push(Command::Close));
    }
    pub fn set_selectable(_: bool) {}
    pub fn change_floating_panes_coordinates(coords: Vec<(PaneId, FloatingPaneCoordinates)>) {
        COMMANDS.with(|c| c.borrow_mut().push(Command::Position(coords)));
    }
    pub fn pipe_message_to_plugin(message: MessageToPlugin) {
        COMMANDS.with(|c| c.borrow_mut().push(Command::Launch(message)));
    }
    pub fn take() -> Vec<Command> {
        COMMANDS.with(|c| std::mem::take(&mut *c.borrow_mut()))
    }
    pub fn clear() {
        take();
    }
    pub fn launch() -> MessageToPlugin {
        let mut commands = take();
        assert_eq!(commands.len(), 1);
        match commands.remove(0) {
            Command::Launch(m) => m,
            _ => panic!("expected launch"),
        }
    }
}
