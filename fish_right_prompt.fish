function agnoster::rvm
  if [ $DEFAULT_RVM_VERSION ]
    if [ $rvm_ruby_string ]
      set ruby_string (echo $rvm_ruby_string | sed s/ruby-//g)

      if [ $ruby_string != $DEFAULT_RVM_VERSION ]
        echo -n "⬥ $ruby_string "
      end
    end
  end
end

function agnoster::git_diff
  agnoster::git::is_repo; or return

  set diff_state (git diff --shortstat)
  [ $diff_state ]; or return

  set files_change (echo $diff_state | grep -o -e "[^ ]* file" | sed "s/ file//g")
  set insertions (echo $diff_state | grep -o -e "[^ ]* insertion" | sed "s/ insertion//g")
  set deletions (echo $diff_state | grep -o -e "[^ ]* deletion" | sed "s/ deletion//g")

  if [ ! $files_change ]; set files_change 0; end
  if [ ! $insertions ]; set insertions 0; end
  if [ ! $deletions ]; set deletions 0; end

  set diff_graph_size 10
  set changes_count (math $insertions + $deletions)

  if math "$changes_count > 10" > /dev/null
    set insertions_on_graph (math "$diff_graph_size * $insertions / $changes_count")
    set deletions_on_graph (math "$diff_graph_size * $deletions / $changes_count")
  else
    set insertions_on_graph $insertions
    set deletions_on_graph $deletions
  end

  echo -n "$files_change"":"
  set_color green
  printf '%*s\n' $insertions_on_graph "" | tr ' ' \u25A3
  set_color red
  printf '%*s\n' $deletions_on_graph "" | tr ' '\u25A3
  echo -n " "
end

function fish_right_prompt
  set_color brblack
  set screen_width (tput cols)

  if math "$screen_width > 40" > /dev/null
    set_color brblack
    agnoster::rvm
  end

  if math "$screen_width > 52" > /dev/null
    set_color brblack
    agnoster::git_diff
  end

  set_color normal
end
