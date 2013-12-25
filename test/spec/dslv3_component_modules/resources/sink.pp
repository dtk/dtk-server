class temp::sink(
  $members = 'test',
  $param1 = 'param1-val'
)
{
  temp::notice_element { $members: }
}

define temp::notice_element()
{
  notice($name)
}
