{ ... }:
{
  programs.aerospace = {
    enable = true;
    package = null;

    settings = {
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.left = 8;
        outer.right = 8;
        outer.top = 8;
        outer.bottom = 8;
      };

      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      workspace-to-monitor-force-assignment = {
        C = [
          "main"
          "secondary"
        ];
        T = [
          "main"
          "secondary"
        ];
        W = [
          "main"
          "secondary"
        ];
        D = [
          "main"
          "secondary"
        ];
        M = [
          "secondary"
          "main"
        ];
        N = [
          "secondary"
          "main"
        ];
        V = "any";
      };

      on-window-detected = [
        {
          "if".app-id = "dev.zed.Zed";
          run = "move-node-to-workspace C";
        }
        {
          "if".app-id = "com.mitchellh.ghostty";
          run = "move-node-to-workspace T";
        }
        {
          "if".app-id = "company.thebrowser.Browser";
          run = "move-node-to-workspace W";
        }
        {
          "if".app-id = "app.zen-browser.zen";
          run = "move-node-to-workspace W";
        }
        {
          "if".app-id = "app.tablepro.TablePlus";
          run = "move-node-to-workspace D";
        }
        {
          "if".app-id = "com.docker.docker";
          run = "move-node-to-workspace D";
        }
        {
          "if".app-id = "com.tinyspeck.slackmacgap";
          run = "move-node-to-workspace M";
        }
        {
          "if".app-id = "ru.keepcoder.Telegram";
          run = "move-node-to-workspace M";
        }
        {
          "if".app-id = "com.culturedcode.ThingsMac";
          run = "move-node-to-workspace N";
        }
        {
          "if".app-id = "md.obsidian";
          run = "move-node-to-workspace N";
        }
        {
          "if".app-id = "com.colliderli.iina";
          run = "move-node-to-workspace V";
        }
        {
          "if".app-id = "com.pixelmatorteam.pixelmator.x";
          run = "move-node-to-workspace V";
        }
      ];

      mode.main.binding = {
        ctrl-left = "focus left";
        ctrl-down = "focus down";
        ctrl-up = "focus up";
        ctrl-right = "focus right";

        ctrl-shift-left = "move left";
        ctrl-shift-down = "move down";
        ctrl-shift-up = "move up";
        ctrl-shift-right = "move right";

        ctrl-minus = "resize smart -50";
        ctrl-equal = "resize smart +50";

        ctrl-slash = "layout tiles horizontal vertical";
        ctrl-comma = "layout accordion horizontal vertical";
        ctrl-f = "fullscreen";
        ctrl-shift-f = "layout floating tiling";

        ctrl-1 = "workspace C";
        ctrl-2 = "workspace T";
        ctrl-3 = "workspace W";
        ctrl-4 = "workspace D";
        ctrl-5 = "workspace M";
        ctrl-6 = "workspace N";
        ctrl-7 = "workspace V";

        ctrl-shift-1 = "move-node-to-workspace C";
        ctrl-shift-2 = "move-node-to-workspace T";
        ctrl-shift-3 = "move-node-to-workspace W";
        ctrl-shift-4 = "move-node-to-workspace D";
        ctrl-shift-5 = "move-node-to-workspace M";
        ctrl-shift-6 = "move-node-to-workspace N";
        ctrl-shift-7 = "move-node-to-workspace V";

        ctrl-shift-semicolon = "mode service";
      };

      mode.service = {
        binding = {
          esc = [
            "reload-config"
            "mode main"
          ];
          r = [
            "flatten-workspace-tree"
            "mode main"
          ];
          ctrl-shift-left = [
            "join-with left"
            "mode main"
          ];
          ctrl-shift-down = [
            "join-with down"
            "mode main"
          ];
          ctrl-shift-up = [
            "join-with up"
            "mode main"
          ];
          ctrl-shift-right = [
            "join-with right"
            "mode main"
          ];
        };
      };
    };
  };
}
