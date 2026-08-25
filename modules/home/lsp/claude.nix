{ config, pkgs }:
let
  inherit (pkgs) lib;
  inherit (import ./tools.nix { inherit pkgs; }) tools;

  marketplace = "dotfiles";
  root = ".local/share/claude-lsp";

  # Plugin names are what `enabledPlugins` keys on; renaming one re-registers it
  # and drops the tracked settings key.
  plugins = lib.listToAttrs (
    map (tool: {
      name = tool.claude.plugin;
      value = {
        inherit (tool.claude) description;
        servers.${tool.claude.server} = {
          inherit (tool) command;
          inherit (tool.claude) extensionToLanguage;
        }
        // lib.optionalAttrs (tool.args != [ ]) { inherit (tool) args; }
        // lib.optionalAttrs (tool.claude ? settings) { inherit (tool.claude) settings; };
      };
    }) (lib.filter (tool: tool ? claude) (lib.attrValues tools))
  );

  names = builtins.attrNames plugins;

  manifests = lib.listToAttrs (
    map (name: {
      name = "${root}/plugins/${name}/.claude-plugin/plugin.json";
      value.text = builtins.toJSON {
        inherit name;
        version = "1.0.0";
        author.name = "zengraf";
        description = plugins.${name}.description;
        lspServers = plugins.${name}.servers;
      };
    }) names
  );
in
{
  files = manifests // {
    "${root}/.claude-plugin/marketplace.json".text = builtins.toJSON {
      name = marketplace;
      description = "Nix-managed LSP servers for Claude Code";
      owner.name = "zengraf";
      plugins = map (name: {
        inherit name;
        source = "./plugins/${name}";
        description = plugins.${name}.description;
      }) names;
    };
  };

  # `claude plugin install` writes enabledPlugins into ~/.claude/settings.json, which is a read-only
  # store symlink — so the plugins are declared here rather than installed.
  settings = {
    extraKnownMarketplaces.${marketplace}.source = {
      source = "directory";
      path = "${config.home.homeDirectory}/${root}";
    };
    enabledPlugins = lib.listToAttrs (
      map (name: {
        name = "${name}@${marketplace}";
        value = true;
      }) names
    );
  };
}
