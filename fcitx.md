mkdir ~/Work/omarchy
git clone https://github.com/omacom-io/omarchy-pkgs.git ~/Work/omarchy/omarchy-pkgs

omarchy dev pkg test omarchy-settings-dev ~/.local/share/omarchy

systemctl --user daemon-reload
systemctl --user enable --now omarchy-fcitx5.service
systemctl --user status omarchy-fcitx5.service
