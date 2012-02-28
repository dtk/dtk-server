class hdp-hbase::client(
  $opts = {}
)
{
  #assumption is there are no other hbase components on node
  hdp-hbase::common { 'hbase': }
}
