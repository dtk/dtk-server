class hdp-hbase::client(
  $opts = {}
)
{
  #assumption is theer are no other hbase components on node
  #TODO: may put in built in delay
  hdp-hbase::common { 'hbase': }
}
