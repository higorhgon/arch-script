#!/bin/sh

# Recuperação do hyprlock quando ele crasha
hyprctl eval --instance 0 'hl.config({ misc = { allow_session_lock_restore = true } })'

# Executar hyprlock no início da sessão
hyprctl dispatch --instance 0 'hl.dsp.exec_cmd("hyprlock")'
