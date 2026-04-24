get_descendants() {
  local parent=$1
  echo $parent
  for child in $(pgrep -P $parent); do
    get_descendants $child
  done
}

get_descendants $1
