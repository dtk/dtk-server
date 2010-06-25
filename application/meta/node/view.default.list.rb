R8View::Views[:node] = {
  :default => {
    :list => {
      :trClass => 'tr-dl',
      :trOddClass => 'tr-dl-odd',
      :trEvenClass => 'tr-dl-even',
      :hiddenFields => [
          {:id => {
            :required => true,
            :type => 'hidden',
          }}
      ],
      :fieldList => [
          {:display_name => {
            :type => 'text',
            :help => '',
            :objLink => true,
            :objLinkView => 'display',
          }},
          {:description => {
            :type => 'text',
            :help => '',
          }},
      ]
    }
  }
}
