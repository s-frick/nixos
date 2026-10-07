# Ponytail-Audit: nixos-Repo

Stand: 2026-10-07

Rund 530 Zeilen und 8 Abhängigkeiten (1 Flake-Input, 7 Neovim-Plugins) lassen sich streichen, ohne Verhalten zu verlieren. Fast 70 % davon liegen im Neovim-Modul.

Die Nummern (Nr) entsprechen der ursprünglichen Rangliste, damit Aufträge wie „fix 2 und 5“ weiter funktionieren. Zeilenangaben sind Schätzungen.

**Schweregrad**

- **Hoch**: über 50 Zeilen oder ganzer toter Teilbaum
- **Mittel**: 10–50 Zeilen oder doppelt ausgeführte Logik
- **Niedrig**: unter 10 Zeilen, kosmetisch

**Status**: ✅ erledigt

**Tags**: `delete` toter Code · `native` Plattform kann es schon · `reuse` existiert bereits im Repo · `yagni` Option/Abstraktion ohne Nutzer · `shrink` gleiche Logik, kürzer

| Modul | Befunde | Zeilen (≈) | Deps |
| --- | --- | --- | --- |
| Neovim | 13 | −410 | −7 |
| Flake & Hosts | 5 | −70 | −1 |
| Home-Manager Common | 4 | −35 | 0 |
| Desktop / Mango | 2 | −18 | 0 |
| Claude-Module | 1 | −6 | 0 |

> Nr. 1, 3 und 5 vor dem Löschen prüfen: Kein Aufrufer per grep gefunden, manuelle `:lua`-Nutzung aber möglich.

## Neovim (`modules/nvim`)

Drei tote Teilbäume (Java-Test-Helfer, neotest, LSP-Wrapper) machen allein rund 280 Zeilen aus.

### Hoch

| Nr | Tag | Befund | Ersatz | Ort | Zeilen (≈) |
| --- | --- | --- | --- | --- | --- |
| ✅ 1 | delete | `test_all_test_classes`, `test_current_package`, `find_all_test_files`: kein Aufrufer, kein Keymap, kein Command | nichts | `lua/jdtls_setup.lua:212-321` | −110 |
| ✅ 2 | native | Sechs `lua/lsp/*.lua`-Wrapper rufen nur `vim.lsp.config` + `enable`; sechs gleiche `setup{capabilities, on_attach}`-Aufrufe | Tabellen nach `nvim/lsp/<name>.lua` (Neovim 0.11 lädt sie selbst), einmal `vim.lsp.config('*', {capabilities})`, einmal `vim.lsp.enable{...}`; `cmd`/`filetypes`/`root_markers` streichen, wo sie lspconfig-Defaults wiederholen; ungenutztes `util`-require und ignoriertes `single_file_support` raus | `lua/lsp/*`, `init.lua:126-158` | −100 |
| ✅ 3 | delete | neotest-Stack nie geladen: `java_neotest.lua`, `neotest-jdtls`-Derivation, zwei auskommentierte Derivationen, Plugins `neotest`, `nvim-nio`, `FixCursorHold-nvim` (seit nvim 0.8 überflüssig) | nichts; jdtls belegt `<leader>tn`/`tN` schon | `default.nix:10-64,205-207,258`, `lua/java_neotest.lua` | −70 |

### Mittel

| Nr | Tag | Befund | Ersatz | Ort | Zeilen (≈) |
| --- | --- | --- | --- | --- | --- |
| ✅ 4 | shrink | nvim-dap-virtual-text-Setup wiederholt alle Defaults | `require("nvim-dap-virtual-text").setup{ virt_text_pos = 'eol' }` | `lua/dap_ui_widgets.lua:22-57` | −33 |
| ✅ 5 | delete | `image_nvim.lua` nie required, Plugin `image-nvim` nie eingerichtet | nichts | `lua/image_nvim.lua`, `default.nix:199` | −31 |
| ✅ 16 | shrink | jdtls-Guards: `pcall(require,"jdtls")` (Nix installiert es immer), Fallback auf `jdt-language-server` (Paket liefert `jdtls`), `missing`-Buchführung (Env-Var-Guard bewusst behalten: verhindert Abbruch in veralteter Shell) | `local cmd = { "jdtls", "-data", workspace_dir }` | `lua/jdtls_setup.lua:5-9,47-90` | −20 |
| ✅ 10 | delete | `on_attach` in jeder Server-Config und in jdtls, obwohl `LspAttach` schon `keymap.on_attach` für jeden Client aufruft: Keymaps werden doppelt gesetzt | nur der Autocmd; jdtls behält nur Java-Maps | `init.lua:128-157`, `lua/jdtls_setup.lua:105` | −15 |
| ✅ 11 | delete | `has_server` + `m.servers`-Prüfung: kein Mapping hat ein `servers`-Feld | `if m.scope == "lsp"` | `lua/keymaps.lua:2-11,153` | −12 |

### Niedrig

| Nr | Tag | Befund | Ersatz | Ort | Zeilen (≈) |
| --- | --- | --- | --- | --- | --- |
| ✅ 18 | delete | tmux, ripgrep, fd doppelt (home-common hat sie); `lib.mkAfter` unnötig, Listen werden ohnehin gemerged (auch in commonlisp) | nichts | `default.nix:88-111`, `modules/commonlisp/default.nix:3` | −4 |
| ✅ 17 | delete | `withNodeJs = true` (init.lua schaltet Node-Provider ab), `withRuby`, `python3.withPackages pynvim` (`withPython3` liefert es) | nichts | `default.nix:167-176` | −3 |
| ✅ 23 | shrink | doppelte `local next`-Zeile, globaler `_initialized`-Guard | Zeile und Guard streichen | `lua/todo-lists.lua:42-43,58-59` | −3 |
| ✅ 20 | delete | Plugins `catppuccin-nvim` und `mini-icons` ungenutzt (gruber-darker und devicons aktiv) | nichts | `default.nix:249,251` | −2 |
| ✅ 22a | delete | `p.yaml` doppelt in Treesitter-Liste; `cargoHash` wirkungslos, weil `cargoDeps` überschrieben | nichts | `default.nix:227,76` | −2 |

## Desktop / Mango (`modules/windowManager/mango`)

### Mittel

| Nr | Tag | Befund | Ersatz | Ort | Zeilen (≈) |
| --- | --- | --- | --- | --- | --- |
| ✅ 6 | delete | Doppelte systemPackages: git, vim, gnumake (nixos.nix), tmux, tree, lazygit (home-common), xdg-desktop-portal* (`xdg.portal`), pipewire, wireplumber (`services.pipewire`), coreutils-full; vermutlich auch `dmsPackages`, weil das HM-Modul `dank-material-shell` dms ohnehin installiert | nichts | `default.nix:95-135` | −12 |

### Niedrig

| Nr | Tag | Befund | Ersatz | Ort | Zeilen (≈) |
| --- | --- | --- | --- | --- | --- |
| ✅ 15 | yagni | Option `extraPackages`, kein Host setzt sie | nichts | `default.nix:22-26,136` | −6 |

## Flake & Hosts (`flake.nix`, `hosts/*`)

### Mittel

| Nr | Tag | Befund | Ersatz | Ort | Zeilen (≈) |
| --- | --- | --- | --- | --- | --- |
| ✅ 7 | shrink | Drei gleich aufgebaute `nixosSystem`-Blöcke; ungenutzte destrukturierte Args (mangowc, dgop, dankMaterialShell, forgejo-mcp-src, impermanence, sops-nix) | `mkHost = name: extra: nixpkgs.lib.nixosSystem { specialArgs = { inherit inputs; }; modules = extra ++ [ ./hosts/${name}/configuration.nix ./modules/common ]; };` und `{ self, nixpkgs, nixos-wsl, home-manager, ... }@inputs` | `flake.nix:49-98` | −29 |
| ✅ 9 | reuse | direnv-Block in drei Hosts kopiert, podman-Block in drei Hosts kopiert | direnv nach `home-common.nix`, podman nach `nixos.nix` oder in ein gemeinsames Modul | `hosts/{fuji,wsl,ubuntu}/home.nix`, `hosts/{fuji,silverback,wsl}/configuration.nix` | −24 |

### Niedrig

| Nr | Tag | Befund | Ersatz | Ort | Zeilen (≈) |
| --- | --- | --- | --- | --- | --- |
| ✅ 19 | delete | `users.users.sebi.isNormalUser` in drei Hosts (steht schon in nixos.nix); `../../modules/common` in silverback und wsl erneut importiert (flake.nix fügt es schon hinzu) | nichts | `hosts/*/configuration.nix` | −9 |
| ✅ 14 | delete | Flake-Input `dgop`; einzige Nutzung (`follows`) auskommentiert | nichts | `flake.nix:19-22,27,56` | −6 |
| ✅ 22b | delete | Leeres `home.packages = [ ]` in fuji und wsl | nichts | `hosts/{fuji,wsl}/home.nix` | −5 |

## Home-Manager Common (`modules/common`)

### Mittel

| Nr | Tag | Befund | Ersatz | Ort | Zeilen (≈) |
| --- | --- | --- | --- | --- | --- |
| ✅ 8 | delete | `input-overlay-presets`-Fetch und auskommentierter OBS-Block | nichts | `home-common.nix:7-14,43-61` | −20 |

### Niedrig

| Nr | Tag | Befund | Ersatz | Ort | Zeilen (≈) |
| --- | --- | --- | --- | --- | --- |
| ✅ 12 | yagni | Default-Liste von `my.tmuxSessionizer.paths`; alle vier Hosts überschreiben sie | `default = [ ];` | `home-options.nix:13-22` | −9 |
| ✅ 22c | delete | Auskommentierte Overlays | nichts | `nixos.nix:10-14` | −5 |
| ✅ 21 | delete | tmux-`extraConfig` wiederholt `set -g base-index 1` und `set -g mode-keys vi` (`baseIndex`/`keyMode`) | nichts | `home-common.nix:155,157` | −2 |

## Claude-Module (`modules/claude-caveman`, `modules/claude-ponytail`)

### Niedrig

| Nr | Tag | Befund | Ersatz | Ort | Zeilen (≈) |
| --- | --- | --- | --- | --- | --- |
| ✅ 13 | reuse | caveman baut den jq-Hook-Check zweimal inline; ponytail hat dafür schon `addHook event script` | gemeinsamen Helper (z. B. `modules/claude-hooks.nix`) in beiden nutzen | `modules/claude-caveman/default.nix:34-42` | −6 |
