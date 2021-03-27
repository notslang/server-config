# If not running interactively, don't do anything
[[ $- != *i* ]] && return

set -o noclobber
shopt -s globstar

alias cp='cp -i' # avoid overwriting files
alias grep='grep --color=auto'
alias ls='exa'
alias la='exa -lah --git'
alias mv='mv -i' # avoid overwriting files
alias diff='diff --color=auto'

# save all commands to /data/HOSTNAME-bash-history.json
export PROMPT_COMMAND='('
PROMPT_COMMAND+='EXIT_CODE=$?;'
PROMPT_COMMAND+='if [ "$(id -u)" -ne 0 ]; then '
PROMPT_COMMAND+='HISTORY_COMMAND=$(HISTTIMEFORMAT="%s " history 1);'
PROMPT_COMMAND+='PARSED_COMMAND=$(echo $HISTORY_COMMAND | cut -d " " -f 3- | jq -M -R ".");'
PROMPT_COMMAND+='if [[ $PARSED_COMMAND != "\"\"" ]]; then '
PROMPT_COMMAND+='COMMAND_NUMBER=$(echo $HISTORY_COMMAND | cut -d " " -f 1);'
PROMPT_COMMAND+='COMMAND_TIME=$(echo $HISTORY_COMMAND | cut -d " " -f 2);'
PROMPT_COMMAND+='WORKING_DIR=$(pwd | jq -M -R ".");'
PROMPT_COMMAND+='echo "{\"time\":$COMMAND_TIME,\"pwd\":$WORKING_DIR,\"command\":$PARSED_COMMAND,\"exit_code\":$EXIT_CODE,\"command_number\":$COMMAND_NUMBER}" >> /data/$HOSTNAME-bash-history.json;'
PROMPT_COMMAND+='fi '
PROMPT_COMMAND+='fi);'

PS1='[\u@\h \W]\$ '
