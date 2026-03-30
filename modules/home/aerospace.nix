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
        alt-left = "focus left";
        alt-down = "focus down";
        alt-up = "focus up";
        alt-right = "focus right";

        alt-shift-left = "move left";
        alt-shift-down = "move down";
        alt-shift-up = "move up";
        alt-shift-right = "move right";

        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";
        alt-f = "fullscreen";
        alt-shift-f = "layout floating tiling";

        alt-1 = "workspace C";
        alt-2 = "workspace T";
        alt-3 = "workspace W";
        alt-4 = "workspace D";
        alt-5 = "workspace M";
        alt-6 = "workspace N";
        alt-7 = "workspace V";

        alt-shift-1 = "move-node-to-workspace C";
        alt-shift-2 = "move-node-to-workspace T";
        alt-shift-3 = "move-node-to-workspace W";
        alt-shift-4 = "move-node-to-workspace D";
        alt-shift-5 = "move-node-to-workspace M";
        alt-shift-6 = "move-node-to-workspace N";
        alt-shift-7 = "move-node-to-workspace V";

        alt-shift-semicolon = "mode service";
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
          alt-shift-left = [
            "join-with left"
            "mode main"
          ];
          alt-shift-down = [
            "join-with down"
            "mode main"
          ];
          alt-shift-up = [
            "join-with up"
            "mode main"
          ];
          alt-shift-right = [
            "join-with right"
            "mode main"
          ];
        };
      };
    };
  };
}
