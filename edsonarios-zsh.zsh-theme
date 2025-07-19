# edsonarios-zsh.zsh-theme
# Two-line prompt modeled after Oh My Bash "edsonarios".
# Segments: status lightning • time • path • [conda] • (git branch *+ flags)
# Second line: ❯_
#
# Flags:
#   *  = unstaged or untracked changes
#   +  = staged changes
#
# Config:
#   export EDSONARIOS_SHOW_BASE_ENV=false   # hide [base]
#
# Requires: setopt prompt_subst (done below), oh-my-zsh colors.

setopt prompt_subst
autoload -U colors && colors

# Colors ----------------------------------------------------------------
local _ed_col_time=$fg_bold[yellow]
local _ed_col_path=$fg_bold[cyan]
local _ed_col_env=$fg_bold[purple]
local _ed_col_git=$fg_bold[magenta]
local _ed_col_prompt_ok=$fg_bold[green]
local _ed_col_prompt_bad=$fg_bold[brown]
local _ed_rst="%{$reset_color%}"

# Whether to show [base] env name; default true
: ${EDSONARIOS_SHOW_BASE_ENV:=true}

# -----------------------------------------------------------------------
# Conda env segment
# -----------------------------------------------------------------------
_ed_conda_env() {
  local env=""
  if [[ -n $CONDA_DEFAULT_ENV ]]; then
    if [[ $CONDA_DEFAULT_ENV == base && $EDSONARIOS_SHOW_BASE_ENV != true ]]; then
      return
    fi
    env=$CONDA_DEFAULT_ENV
  elif [[ -n $MAMBA_DEFAULT_ENV ]]; then
    env=$MAMBA_DEFAULT_ENV
  fi
  [[ -z $env ]] && return
  # leading space
  printf '%s' " %{${_ed_col_env}%}[${env}]${_ed_rst}"
}

# -----------------------------------------------------------------------
# Git segment: (branch [*][+])
# -----------------------------------------------------------------------
_ed_git_segment() {
  git rev-parse --is-inside-work-tree &>/dev/null || return

  local br
  br=$(git symbolic-ref --quiet --short HEAD 2>/dev/null \
     || git describe --tags --exact-match 2>/dev/null \
     || git rev-parse --short HEAD 2>/dev/null) || return

  local flags="" have_unstaged=0 have_staged=0

  # staged?
  if ! git diff --quiet --ignore-submodules --cached 2>/dev/null; then
    have_staged=1
  fi
  # unstaged?
  if ! git diff --quiet --ignore-submodules 2>/dev/null; then
    have_unstaged=1
  fi
  # untracked files count as unstaged dirt
  if [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]]; then
    have_unstaged=1
  fi

  [[ $have_unstaged == 1 ]] && flags+="*"
  [[ $have_staged   == 1 ]] && flags+="+"

  if [[ -n $flags ]]; then
    printf '%s' " %{${_ed_col_git}%}(${br} ${flags})${_ed_rst}"
  else
    printf '%s' " %{${_ed_col_git}%}(${br})${_ed_rst}"
  fi
}

# -----------------------------------------------------------------------
# First line lightning – colored by last status using %(?.. ..)
# %(?.GOOD.BAD) expands GOOD if exit status == 0 else BAD
# -----------------------------------------------------------------------
# We build these into PROMPT; no function call needed for status color.

# -----------------------------------------------------------------------
# PROMPT assembly
# %D{%H:%M:%S} -> 24h time
# %~           -> path (~ for $HOME)
# $(...)       -> our segments run at prompt expansion time
# -----------------------------------------------------------------------
PROMPT='%(?.%{${_ed_col_time}%}⚡.%{$fg_bold[red]%}⚡) %{$fg_bold[yellow]%}%D{%H:%M:%S} %{${_ed_col_path}%}%~%{$reset_color%}$( _ed_conda_env )$( _ed_git_segment )
%{${_ed_col_prompt_ok}%}❯_%{$reset_color%} '

RPROMPT=''
