function agnoster::set_default
  set name $argv[1]
  set -e argv[1]
  set -q $name; or set -g $name $argv
end

agnoster::set_default AGNOSTER_SEGMENT_SEPARATOR '' \u2502
agnoster::set_default AGNOSTER_SEGMENT_RSEPARATOR '' \u2502

agnoster::set_default AGNOSTER_BEFORE_LINE ""
agnoster::set_default AGNOSTER_AFTER_LINE ""
agnoster::set_default AGNOSTER_SHOW_PROMPT 0

agnoster::set_default AGNOSTER_ICON_ERROR \u2717
agnoster::set_default AGNOSTER_ICON_ROOT \u26a1
agnoster::set_default AGNOSTER_ICON_BGJOBS \u2699

agnoster::set_default AGNOSTER_ICON_SCM_BRANCH \u2387
agnoster::set_default AGNOSTER_ICON_SCM_REF \u27a6
agnoster::set_default AGNOSTER_ICON_SCM_STAGED '…'
agnoster::set_default AGNOSTER_ICON_SCM_STASHED '~'

function agnoster::segment --desc 'Create prompt segment'
  set bg $argv[1]
  set fg $argv[2]
  set -e argv[1] argv[2]
  set content $argv

  set_color -b $bg

  if set -q __agnoster_background; and [ "$__agnoster_background" != "$bg" ]
    set_color "$__agnoster_background"; echo -n "$AGNOSTER_SEGMENT_SEPARATOR[1]"
  end

  if [ -n "$content" ]
    set -g __agnoster_background $bg
    set_color -b $bg $fg
    if [ $content != " " ]
      echo -n " $content"
      set -g agnoster_prompt_string "$agnoster_prompt_string $content$AGNOSTER_SEGMENT_SEPARATOR[1]"
    else
      echo -n " "
      set -g agnoster_prompt_string "$agnoster_prompt_string "
    end
  end
end

function agnoster::environment
  set -g agnoster_screen_width (tput cols)
  set -g agnoster_prompt_string ""
end

function agnoster::context
  if [ (id -u $USER) -eq 0 ]
    set icons $icons "$AGNOSTER_ICON_ROOT"
  end
  if [ (jobs -l | wc -l) -ne 0 ]
    set icons $icons "$AGNOSTER_ICON_BGJOBS"
  end

  if [ (uname) = 'Darwin' ]
    set user (whoami)
    set host (scutil --get ComputerName | sed "s/MacBook Pro[ ]*/MBP/g" | sed "s/MacBook Air[ ]*/MBA/g" | sed "s/ 的 /'s /g" | sed "s/$USER's //g" | sed "s/ /_/g")
    set user_and_host "$user@$host"
  else
    set user (whoami)
    set host (hostname)
    set user_and_host "$user@$host"
  end

  if set -q icons
    agnoster::segment black normal "$user_and_host $icons"
  else
    agnoster::segment black normal "$user_and_host"
  end

  if [ "$__agnoster_last_status" -ne 0 ]
    agnoster::segment black red "$AGNOSTER_ICON_ERROR "
  else
    agnoster::segment black normal " "
  end
end

# Git {{{
# Utils {{{
function agnoster::git::is_repo
  command git rev-parse --is-inside-work-tree ^/dev/null >/dev/null
end

function agnoster::git::color
  if command git diff --no-ext-diff --quiet --exit-code
    echo "green"
  else
    echo "yellow"
  end
end

function agnoster::git::branch
  set -l ref (command git symbolic-ref HEAD ^/dev/null)
  if [ "$status" -ne 0 ]
    set -l branch (command git show-ref --head -s --abbrev | head -n1 ^/dev/null)
    set ref "$AGNOSTER_ICON_SCM_REF $branch"
  end
  echo "$ref" | sed "s|\s*refs/heads/|$AGNOSTER_ICON_SCM_BRANCH |1"
end

function agnoster::git::ahead
  command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null | \
    awk '
      />/ {a += 1}
      /</ {b += 1}
      {if (a > 0 && b > 0) nextfile}
      END {
        if (a > 0 && b > 0)
          print "±";
        else if (a > 0)
          print "+";
        else if (b > 0)
          print "-"
      }'
end

# }}}

function agnoster::git -d "Display the actual git state"
  agnoster::git::is_repo; or return

  set -l branch (agnoster::git::branch)
  set -l ahead (agnoster::git::ahead)

  set -l content "$branch$ahead$staged$stashed"

  agnoster::segment (agnoster::git::color) black "$content "
end
# }}}

function agnoster::prompt_full_pwd
  if test "$PWD" != "$HOME"
    printf "%s" (echo $PWD|sed -e 's|/private||' -e "s|^$HOME|~|")
  else
    echo '~'
  end
end

function agnoster::dir -d 'Print current working directory'
  set -l dir (agnoster::prompt_full_pwd)
  agnoster::segment blue black "$dir "
end

function agnoster::datetime
  if [ $AGNOSTER_AFTER_LINE = \n ]
    set remaining_space (math $agnoster_screen_width - (string length $agnoster_prompt_string))

    if math "$remaining_space > 22" > /dev/null
      set current_datetime (date "+%Y-%m-%d %T")
      agnoster::segment black bryellow "$current_datetime "
    end
  end
end

function agnoster::finish
  agnoster::segment normal normal
  echo -n ' '
  set -e __agnoster_background
end

function fish_prompt
  set -g __agnoster_last_status $status

  echo -n $AGNOSTER_BEFORE_LINE

  agnoster::environment
  agnoster::context
  agnoster::dir
  agnoster::git
  agnoster::datetime
  agnoster::finish

  echo -n $AGNOSTER_AFTER_LINE

  set_color normal
  set_color -b normal

  echo -n $AGNOSTER_PROMPT
end
