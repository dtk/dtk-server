
require 'nokogiri'
require 'erubis'

#
#
#
module R8Tpl

class TemplateR8 

  START_TAG_REGEX = /\{%\s*/
#  END_TAG_REGEX = /\s*.*%\}/
#TODO: revisit when implementing if and iterators
  END_TAG_REGEX = /\s*[\sa-zA-Z0-9_@:\[\]]*%\}/
  CTRL_BLOCK_REGEX = /(#{START_TAG_REGEX}([a-zA-Z_@:\[\]][a-zA-Z0-9_@:\[\]'"=\>\<\|&\(\),.\s\!]*)#{END_TAG_REGEX})/m
  #  /\{%\s*(for|if|end)\s*.*%\}/

  attr_accessor :tpl_path,:tpl_contents,:tpl_results,:tpl_file_handle,
                :template_vars,:js_render_queue,:xhtml_document,:element_count,:ctrl_close_stack,
                :indent,:num_indents,:panel_set_element_id,
                :js_file_handle,:js_file_write_path,:js_tpl_callback,:js_file_name,:js_cache_dir,
                :js_templating_on,
                :root_js_element_var_name,:root_js_hash,:loop_vars,:ctrl_vars,:js_var_header

  def initialize(tpl_path=nil) 
    @js_var_header = 'tplVars'
    @tpl_path = tpl_path
    @tpl_contents = ''
    @tpl_results = nil
    @xhtml_document = nil

    @js_tpl_callback = ''
    @js_file_name = ''

    @js_cache_dir = ''
    @js_file_write_path = ''
    @js_render_queue = []
    @root_js_element_var_name = ''
    @root_js_hash = {}

    @parent_ref_hash = {}

    @node_render_JS = ''
    @header_JS = ''
    @panel_set_element_id = '' #this might not be used, js func should prob return DOM ref

    @num_indents = 0
    @indent = ''

    @js_templating_on = true
    @ctrl_vars = []
    @loop_vars = []

    #this var is needed b/c of the way DOM rendering needs to be handled during if's, loop's
    @ctrl_close_stack = []

    @element_count = 0

 
    @template_vars = {}

    @template_dir = '.'
    @compile_dir = R8::Config[:rtpl_compile_dir]
    @cache_dir = R8::Config[:rtpl_cache_dir]
    @js_file_write_path = R8::Config[:js_file_write_path]

    (R8::Config[:js_templating_on].nil?) ? @js_templating_on = true : @js_templating_on = R8::Config[:js_templating_on]
  end

  def jsTemplatingOn?
    return @js_templating_on
  end

  def assign(name,value=nil)
    @template_vars[name] = value
  end
  def setJSTplName(jsTplName)
    @js_tpl_callback = jsTplName
    @js_file_name = jsTplName+".js"
  end

  def jsQueuePush(type,jscontent)
    @js_render_queue << {:type=>type,:jscontent=>jscontent}
  end

  def renderJsTPL(view_tpl_contents)
    tplToJS(view_tpl_contents)
  end

  def render(view_tpl_contents,js_templating_on=jsTemplatingOn?)
#TODO: should be populating these from global config options
    self.assign(:jsIncludePath, "jsIncludePath")
    self.assign(:siteURL, "this is a test")

    #if jsTemplatingOn? then
    if js_templating_on
      renderJsTPL(view_tpl_contents)
    else
      eruby =  Erubis::Eruby.new(view_tpl_contents,:pattern=>'\{\% \%\}')
      @tpl_results = eruby.result(@template_vars)
    end
  end


  def js_file_write(js_file_handle,contents)
    js_file_handle.write(@indent + contents)
  end

#private
  def tplXMLInit(view_tpl_contents)
    @tpl_contents << "<div>" << self.cleanTpl(view_tpl_contents) << "</div>"

    @xhtml_document = Nokogiri::XML(@tpl_contents,nil,'xml')
    @root_js_element_var_name = @xhtml_document.root.name + '_tplRoot'
  end

  #this will escape &, <, > for xml purposes
  def cleanTpl(str)
    str.gsub!(/&(?!amp;)/m){|match| match+'amp;'}
    matchStr = str
    cleanStr = ''
    while matches = /\{%={0,1}\s*[a-zA-Z0-9\.@:'"\(\)\|\[\]\s\=&]*\s*%\}/.match(matchStr) do
      cleanStr << matches.pre_match
      subbedStr = matches.to_s.gsub('>','&gt;')
      subbedStr.gsub!('<','&lt;')
      matchStr = matches.post_match
      cleanStr << subbedStr
    end
    if(!matches.nil?) then cleanStr << matches.post_match end
    return cleanStr
  end

  def jsTplCurrent?
    false
  end

  def tplToJS(view_tpl_contents)
    if self.jsTplCurrent?
      return nil
    end

    tplXMLInit(view_tpl_contents)
    jsQueuePush('functionheader', "function " + @js_tpl_callback + "(" + @js_var_header + ",renderType) {")
    #add local var ref for document object
    jsQueuePush('functionbody', "var doc = document;")
    createRootNode()
    renderJSDOMTree(@xhtml_document.root.children,@root_js_hash)
    setJSAddContentsToPage()
    jsQueuePush('functionclose', "}")
    writeJSToFile()
  end

  def renderJSDOMTree(nodeList, parentNode=nil)
    for node in nodeList do
        if !node.cdata?
          newJSNode = {
            :jsElementVarName => node.name + @element_count.to_s,
            :elementType => node.name.downcase,
#            :type => node.type,         #do mapping from nokogiri constants to tpl elem types
            :type => node.name.downcase,         #temp until mapping done
            :value => node.content == '' ? '' : node.content,
            :attributes => []
          }

          #if the node has value contents its a text node and process said contents
          if newJSNode[:elementType] == 'text'
            self.processNodeText(newJSNode[:value],!parentNode.nil? ? parentNode[:jsElementVarName] : '', newJSNode[:elementType])
          else
            self.jsQueuePush('node', self.createElementJS(newJSNode[:elementType],newJSNode[:jsElementVarName]))
            @element_count += 1
            self.addAttributes(node,newJSNode)
          end

          childrenNodeList = node.children
          if childrenNodeList.length > 0
            self.renderJSDOMTree(childrenNodeList, newJSNode)
          end

          #if there are children recurse down the tree
#          childrenNodeList.length > 0 ? self.renderJSDOMTree(childrenNodeList, newJSNode) : return

          #this is here by itself b/c of methodology of rendering DOM and appending children AFTER all sub children done
          if !parentNode.nil? && !node.cdata? && newJSNode[:elementType] != 'text'
            self.appendChildJS(parentNode[:jsElementVarName],parentNode[:elementType], newJSNode[:jsElementVarName], newJSNode[:elementType])
          end

          #make this check _dev or _production mode
          #this is temporary, maybe have a general function for adding comments
          if !node.cdata? && newJSNode[:elementType] != 'text'
            self.jsQueuePush('comment',"//end rendering for element " + newJSNode[:jsElementVarName])
          end

          if @ctrl_close_stack.length > 0
            tmpArray = @ctrl_close_stack.pop
            self.jsQueuePush(tmpArray[:type], tmpArray[:jsContent])
          end
        end
    end
  end

  def addAttributes(node,newJSNode)
    for attr in node.attribute_nodes do
      self.addAttrJS(newJSNode[:jsElementVarName],newJSNode[:elementType], attr.name, attr.content)
    end
  end

  def clearIndentation()
    @indent = ''
  end

  def handleIndentation(jsLine)
    case jsLine[:type]
      when "functionheader" then
          @num_indents +=1
      when "forloopheader","ifheader","xhtmlAttrHead" then
          self.setIndentation()
          @num_indents += 1
      when "functionclose","forloopclose","ifclose","end","xhtmlAttrClose" then
          @num_indents -= 1
          self.setIndentation()
      when "xhtmlAttrElse","elsif" then
          @num_indents -= 1
          self.setIndentation()
          @num_indents += 1
      else
          self.setIndentation()
    end
  end

  def setIndentation()
    i = 0
    while i < @num_indents do
      @indent << "\t"
      i += 1
    end
  end

  def writeJSToFile()
    File.open(@js_file_write_path + "/" + @js_file_name, 'w') do |js_file_handle|
      for jsLine in @js_render_queue do
        clearIndentation()
        handleIndentation(jsLine)

        #jsItem[:jscontent] can be single entry or array of jscontent to be written
        #right now only textspans will have multiple entries
        if jsLine[:jscontent].class == Array
           for jsContentItem in jsLine[:jscontent] do
             js_file_write(js_file_handle,jsContentItem + "\n")
             js_file_write(js_file_handle,"\n") if jsLine[:type] == 'comment'
           end
        else
          js_file_write(js_file_handle,jsLine[:jscontent].to_s + "\n")
          js_file_handle.write("\n") if jsLine[:type] == 'comment'
        end
      end
    end
  end

  def createRootNode()
    newJSNode = {
      :jsElementVarName => @xhtml_document.root.name + '_tplRoot',
      :elementType => @xhtml_document.root.name,
      :type => @xhtml_document.root.type,         #do mapping from nokogiri constants to tpl elem types
      :value => @xhtml_document.root.content == '' ? '' : @xhtml_document.root.content,
      :attributes => []
    }
    @root_js_hash = newJSNode
    self.jsQueuePush('node', self.createElementJS(newJSNode[:elementType],newJSNode[:jsElementVarName]))
    self.addAttributes(@xhtml_document.root,newJSNode)
  end

#should probably move the appending out of the templating and just have js return DOM ref to JS ctrlr
  def setJSAddContentsToPage()
    self.jsQueuePush('ifheader', "if(R8.utils.isUndefined(renderType) || renderType !='append') {")
    self.jsQueuePush('renderClear','doc.getElementById("' + @panel_set_element_id + '").innerHTML="";')
    self.jsQueuePush('ifclose', '}')
    self.jsQueuePush('pageAdd','doc.getElementById("' + @panel_set_element_id + '").appendChild(' + @root_js_element_var_name + ');')
  end

  def createElementJS(elemName,jsElementVarName)
    return 'var ' + jsElementVarName + '= document.createElement("' + elemName + '");'
  end

  def addAttrJS(jsElementVarName, elementType, attrName, attrValue)
    elementType.downcase!
    attrName.downcase!
    processedAttrName = self.checkForTPLVars(attrName)
    processedAttrValue = self.checkForTPLVars(attrValue)
    if processedAttrValue == attrValue then processedAttrValue = '"' + processedAttrValue + '"' end

    case attrName
      when "checked" then
        if(elementType == 'input') then
          self.jsQueuePush('xhtmlAttrHead', 'if('+jsElementVarName+'.type==="checkbox") {')
          self.jsQueuePush('ifheader', 'if('+processedAttrValue+' === 1 || '+processedAttrValue+' === "1") {')
          self.jsQueuePush('xhtmlAttrBody', jsElementVarName+'.'+processedAttrName+' = true;')
          self.jsQueuePush('elseif', '} else {')
          self.jsQueuePush('xhtmlAttrBody', jsElementVarName+'.'+processedAttrName+' = false;')
          self.jsQueuePush('ifclose', '}')
          self.jsQueuePush('elseif', '} else if('+jsElementVarName+'.type==="radio") {')
          self.jsQueuePush('ifheader', 'if('+jsElementVarName+'.value === '+processedAttrValue+') {')
          self.jsQueuePush('xhtmlAttrBody', jsElementVarName+'.'+processedAttrName+' = true;')
          self.jsQueuePush('ifclose', '}')
          self.jsQueuePush('xhtmlAttrClose', '}')
        else
          self.jsQueuePush('attribute', jsElementVarName+'.setAttribute("'+processedAttrName+'","'+processedAttrValue+'");')
        end
      when "selected" then
        if(elementType == 'option') then
          self.jsQueuePush('xhtmlAttrHead', 'if('+processedAttrValue+' === '+jsElementVarName+'.value) {')
          self.jsQueuePush('xhtmlAttrBody', jsElementVarName+'.selected = true;')
          self.jsQueuePush('xhtmlAttrClose', '}')
        end
      when "multiselected" then
        if(elementType == 'option') then
          processedAttrValue.gsub!('[]', '')
          self.jsQueuePush('forloopheader', 'for(var '+jsElementVarName+'Value in '+processedAttrValue+') {')
          self.jsQueuePush('xhtmlAttrHead', 'if('+processedAttrValue+'['+jsElementVarName+'Value] === '+jsElementVarName+'.value) {')
          self.jsQueuePush('xhtmlAttrBody', jsElementVarName+'.selected = true;')
          self.jsQueuePush('xhtmlAttrClose', '}')
          self.jsQueuePush('forloopclose', '}')
        end
      when "compact","declare","readonly","disabled","defer","ismap","nohref","noshade","nowrap","multiple","noresize" then
          self.jsQueuePush('attribute', jsElementVarName + '.setAttribute("' + processedAttrName + '",' + processedAttrValue + ');')
      else
#          self.jsQueuePush('attribute', jsElementVarName + '.setAttribute("' + self.checkForTPLVars(attrName) + '","' + self.checkForTPLVars(attrValue) + '");')
          self.jsQueuePush('attribute', jsElementVarName + '.setAttribute("' + processedAttrName + '",' + processedAttrValue + ');')
    end
  end

  def appendChildJS(parentJSElementVarName,parentElementType,childJSElementVarName,childElementType)
    childElementType.downcase!
    parentElementType.downcase!
    case parentElementType
      when "select" then
        if childElementType == 'option'
          self.jsQueuePush('appendChild',parentJSElementVarName + '.add('+childJSElementVarName+');')
        else
          self.jsQueuePush('appendChild',parentJSElementVarName + '.appendChild('+childJSElementVarName+');')
        end
      else
          self.jsQueuePush('appendChild',parentJSElementVarName + '.appendChild('+childJSElementVarName+');')
    end
  end

  def processNodeText(nodeText,parentVarName,parentNodeType)
    nodeText.strip!
    while matches = CTRL_BLOCK_REGEX.match(nodeText) do
=begin
#R8 Debug
p "Matched Value(s):"+matches.to_s
p "Before Matched Value(s):"+matches.pre_match
p "After Matched Value(s):"+matches.post_match
=end
      if matches.pre_match.length > 0
        matches.pre_match.strip!
        if matches.pre_match != ''
          self.setTextSpanJS(matches.pre_match, parentNodeType, parentVarName)
        end
      end

      #process tpl control match js
      self.handleTplCtrl(matches.to_s)

      nodeText = matches.post_match
      nodeText.strip!
    end
    (nodeText != '' && !nodeText.nil?) ? self.setTextSpanJS(nodeText, parentNodeType, parentVarName) : nil
  end

  def setTextSpanJS(text,parentNodeType, parentVarName='', spanClass='')
    parentVarName.downcase!
    #option & textarea elements dont like their contents wrapped in <span> so use var.innerHTML=text
    transformedTxt = self.checkForTPLVars(text)
    if(transformedTxt == text) then transformedTxt = '"'+transformedTxt+'"' end

    case parentNodeType
      when "option", "textarea" then
        self.jsQueuePush('innerHTML', self.retSetInnerHTMLJS(parentVarName,transformedTxt))
      else
        #add a unique number to the textspan js varname to avoid conflicts
        txtSpanNum = @js_render_queue.length.to_s
        jsVarName = 'txtSpan' + txtSpanNum
        jscontentArray = []
        jscontentArray << self.retCreateElementJS('span', jsVarName)
        if spanClass !=''
          #call to newly created func getJSSetClass
        end
        jscontentArray << self.retSetInnerHTMLJS(jsVarName, transformedTxt)
        self.jsQueuePush('textspan', jscontentArray)

        #if parent name = '' it should be a cntrl statement, else its text that should be appended
        if parentVarName != ''
          self.appendChildJS(parentVarName, '', jsVarName, 'span')
        end
    end

  end

  def handleTplCtrl(matchResult)
#R8 DEBUG
#p 'Going to process ctrl statement:  '+matchResult
#    ctrlRegex = /\{%\s*(for|if|end)(.*)%\}/
    ctrlRegex = /\{%\s*(.*)%\}/
    matches = ctrlRegex.match(matchResult)
    case matches[1].strip
      when 'end' then
#TODO:switch this to push onto @ctrl_stack (see php class line 599)
        self.jsQueuePush('forloopclose', '}')
      else
        self.getLoopCtrlJS(matches[1])
    end
#R8 DEBUG
=begin
    for m in 0...matches.length do
p '    Match '+m.to_s+': '+matches[m]
    end
=end
  end

  def getLoopCtrlJS(ctrlStr)
    newLoopHash = {}
    ctrlPieces = ctrlStr.split(' ')
    case ctrlPieces[0]
#TODO: clean this up to probably use all regex's for case comparisons
      when 'for' then
#        loopIndexName = 'lvIndex'+@loop_vars.length.to_s
#should be checking to see if nested here, do it later
        newLoopHash[:ctrlVarName] = ctrlPieces[1].strip
        newLoopHash[:iteratorVarRaw] = ctrlPieces[3].strip
        newLoopHash[:iteratorVar] = ctrlPieces[3].gsub('@','')
        newLoopHash[:loopIndex] = nil
#R8 DEBUG
=begin
p '=====Have a forloop to process====='
p '     LoopContent: '+ctrlPieces.inspect
p '     LoopVarName: '+newLoopHash[:ctrlVarName].to_s
p '     iteratorVarName: '+newLoopHash[:iteratorVar].to_s
p '     iteratorVarRaw: '+newLoopHash[:iteratorVarRaw].to_s
=end
#p 'Going to parse variables with ctr_vars:  '+@ctrl_vars.inspect

        @ctrl_vars << newLoopHash
        varParser = R8Tpl::TplVarParser.new(newLoopHash[:ctrlVarName],@js_var_header,@ctrl_vars)
        varParser.process
        ctrlVarName = varParser.js_var_string
        varParser = R8Tpl::TplVarParser.new(newLoopHash[:iteratorVar],@js_var_header,@ctrl_vars)
        varParser.process
        iteratorVar = varParser.js_var_string

        jsContent = "for(var " + ctrlVarName + " in " + iteratorVar + ") { "
        self.jsQueuePush('forloopheader', jsContent)
      when 'if' then
        ifels_parser = R8Tpl::IfElsExpressionParser.new(ctrlStr,@js_var_header,@ctrl_vars)
        ifels_parser.process
        jsContent = 'if ('+ifels_parser.js_expression_string+') {'
        self.jsQueuePush('ifheader', jsContent)
      when 'elsif'
        ifels_parser = R8Tpl::IfElsExpressionParser.new(ctrlStr,@js_var_header,@ctrl_vars)
        ifels_parser.process
        jsContent = 'elseif ('+ifels_parser.js_expression_string+') {'
        self.jsQueuePush('elsifheader', jsContent)
      when /\?:styleregex/ then
      else
        addLoopIndexVar = false
        ctrlRegex = /\s*([a-zA-Z_@:][a-zA-Z0-9_@\.:\[\]'"]+)(.each_with_index|.each)/
        if(eachMatches = ctrlRegex.match(ctrlPieces[0])) then
          case eachMatches[2]
            when '.each_with_index' then
              addLoopIndexVar = true
          end
        end
        if(addLoopIndexVar == true) then
          varMatches = /\|([a-zA-Z_@:][a-zA-Z0-9_@\.:\[\]'"]+),([a-zA-Z_@:][a-zA-Z0-9_@\.:\[\]'"]+)\|/.match(ctrlPieces[2])

          newLoopHash[:loopIndex] = varMatches[1].strip
          newLoopHash[:ctrlVarName] = varMatches[2].strip
          iteratorVar = ctrlPieces[0].split('.')[0]

          newLoopHash[:iteratorVarRaw] = iteratorVar.strip
          newLoopHash[:iteratorVar] = iteratorVar.strip
        else
          varMatches = /\|([a-zA-Z_@:][a-zA-Z0-9_@\.:\[\]'"]+)\|/.match(ctrlPieces[2])
          newLoopHash[:loopIndex] = nil
          newLoopHash[:ctrlVarName] = varMatches[1].strip
          iteratorVar = ctrlPieces[0].split('.')[0]

          newLoopHash[:iteratorVarRaw] = iteratorVar.strip
          newLoopHash[:iteratorVar] = iteratorVar.strip
        end
        @ctrl_vars << newLoopHash
        varParser = R8Tpl::TplVarParser.new(newLoopHash[:ctrlVarName],@js_var_header,@ctrl_vars)
        varParser.process
        ctrlVarName = varParser.js_var_string
        varParser = R8Tpl::TplVarParser.new(newLoopHash[:iteratorVar],@js_var_header,@ctrl_vars)
        varParser.process
        iteratorVar = varParser.js_var_string

        jsContent = "for(var " + ctrlVarName + " in " + iteratorVar + ") { "
        self.jsQueuePush('forloopheader', jsContent)
    #end else in case ctrlPieces[0] block
    end
  end

  def checkForTPLVars(varText, clean=false)
    varRegex = /(\{%=\s*)([a-zA-Z_@:][a-zA-Z0-9_@\.:\[\]'"]+)(\s*%\})/
    varPostMatchText = varText
    returnText = ''

    while matches = varRegex.match(varPostMatchText) do
      if matches.pre_match != '' then
         returnText == '' ? (returnText << '"' << matches.pre_match << '"') : (returnText << ' + "' << matches.pre_match << '"')
      end

      varParser = R8Tpl::TplVarParser.new(matches[2].to_s,@js_var_header,@ctrl_vars)
      varParser.process
      processedVarTxt = varParser.js_var_string

      if processedVarTxt != '' then
        returnText == '' ? (returnText <<  processedVarTxt) : (returnText << " + " << processedVarTxt)
      end

      varPostMatchText = matches.post_match
    end
    if varPostMatchText != varText && varPostMatchText !='' then
       returnText == '' ? (returnText << '"' << varPostMatchText << '"') : (returnText << ' + "' << varPostMatchText << '"')
    end
#TODO: decide if quote addition can be removed, causing issues when processing attributes
    returnText == '' ? (return varText) : (return returnText)
  end

  def retSetInnerHTMLJS(jsElementVarName, innerContent='')
#TODO: should make a config option to strip whitespace or not
#    innerContent.strip!
    retVar = jsElementVarName + '.innerHTML = ' + innerContent + ';'
    return retVar
  end

  def retCreateElementJS(tagName, jsElementVarName)
    return 'var ' + jsElementVarName + '= document.createElement("' + tagName + '");'
  end

##################BEGIN NEW TEMPLATE STUBS FOR VIEW HANDLING#################################
#from_view might need some explanation, used in case of one global Template object for request
#   used as flag then Template called within meta view cache generation where its not possible to have a metaview
  def set_view(view_name,from_view=false)
    profile = user.current_profile

    if(strstr(view_name,'/'))
      view_pieces = preg_split('/\//', view_name)
      @model_name = view_pieces[0]
      @view_name = view_pieces[1]
    else
      @model_name = '';
      @view_name = view_name;
    end

    if(!from_view && ViewR8.hasMetaView(@model_name,profile,@view_name))
      #make sure that base smarty engine knows where to look instead of default view folder
      self.set_view_dir("model_cache")
      if(!File.exists?(@tpl_dir+'/'+@model_name)) FileUtils.mkdir_p(@tpl_dir+'/'+@model_name,0,true)

      #now make sure meta tpl cache is up to date
      ViewR8.update_cache(@model_name,@view_name,profile)
      @current_view = ViewR8.view_tpl_name
    else
#TODO: revisit when deeper into profiles, currently too messy
      profile_tpl_name = @tpl_dir+'/'+profile+'.'+@view_name
      default_tpl_name = @tpl_dir+'/'+@view_name
      if(File.exists?(profile_tpl_name))
        @current_view = @profile.'.'.@view_name
      else
        @current_view = @view_name
      end
    end

    if(@model_name !='') @current_view = @model_name+'/'+@current_view
  end


end
end
########################################################

module R8Tpl

class TplVarParser

  attr_accessor :var_name,:cur,:cur_stack,:var_string,:length,:prev_char,:char,:next_char,
                :keys,:eov,:js_var_string,:js_var_header,:ctrl_var_mappings,
                :is_hash

  def initialize(varString,jsVarHeader='rtplVars',ctrlVarMappings=nil)
    @var_string = varString
    @js_var_string = ''
    if self.invalid? then return false end
    @js_var_header = jsVarHeader
    @keys = []
    @cur = 0
    @length = @var_string.length #public
    @prev_char = ''
    @char = @var_string[0].chr
    @next_char = ''
    @cur_stack = []
    ctrlVarMappings.nil? ? @ctrl_var_mappings = [] : @ctrl_var_mappings = ctrlVarMappings       #private, should probably be passed in constructor

    @var_name = ''
    @eov = false
    (varString.include?('[')) ? @is_hash = true : @is_hash = false
    self.setVarName
  end

  def invalid?
    chr = @var_string[0].chr
    intMatch = Integer(chr) rescue false
    if chr == nil || chr == '' then return true
    elsif intMatch == true then return true
    else return false
    end
  end

  def setVarName
    while @char != '[' && @char != ']' && @cur < @length do
      @var_name << @char
      self.advCur
    end
    self.advCur
  end

  def advCur(num=1)
    while num > 0 do
      if @cur < @length then 
        @cur +=1
      else num = 0 end
      num -=1
    end

    if @cur == @length then
      @eov = true
      return nil
    else
      @prev_char = @char
      @char = @var_string[@cur].chr
      (@var_string[@cur+1].nil?) ? @next_char = nil : @next_char = @var_string[@cur+1].chr
      return @cur
    end
  end

  def to_s
    #change this to return current representation of rendered hash variable
    return @var_string
  end

  def process
    while !self.eov? do
      if self.atHashStart?
        self.setHashKey
      end
      self.advCur
    end
    self.var2JS
  end

  def var2JS
    @js_var_string << self.getJSVarName
    @keys.each { |key|
      if key[:type] == 'literal' then @js_var_string << "['" << key[:txt] << "']"
      elsif key[:type] == 'var' then @js_var_string << "[" << key[:txt] << "]"
      end
    }
  end

  def getJSVarName
    if @ctrl_var_mappings.length == 0 then
      return @js_var_header + "['" + @var_name.gsub('@','') + "']"
    else
      @ctrl_var_mappings.each do |ctrl_var|
        if ctrl_var[:ctrlVarName] == @var_name then 
          (@is_hash) ? 
          (return @js_var_header + "['" + ctrl_var[:iteratorVar] + "']["+@var_name+"]") : 
          (return @var_name)
        end
      end
    end
    return @js_var_header + "['" + @var_name.gsub('@','') + "']"
  end

  def atHashStart?
    @prev_char == '[' ? (return true) : (return false)
  end

  def isVarKey?
    intKey = Integer(@char) rescue false
    if intKey then return false end
    case @char
    when '"',"'",":" then
       return false
    end

    return true
  end

  def getInnerVarString
    numOpenHashes = 1
    innerStr = ''
    while @char != ']' && numOpenHashes > 0 do
      innerStr << @char
      if @char == '[' then numOpenHashes +=1
      elsif @char == ']' then numOpenHashes -=1
      end
      self.advCur
    end
    return innerStr
  end

  def setHashKey
    if self.isVarKey? then
      innerVarString = self.getInnerVarString
      varKeyParser = R8Tpl::TplVarParser.new(innerVarString,@js_var_header,@ctrl_var_mappings)
      varKeyParser.process
      newKey = {
#        :txt => innerVarString,
        :txt => varKeyParser.js_var_string,
        :type => 'var',
        :varRef => varKeyParser
      }
    else
      newKey = {
        :txt => '',
        :type => 'literal'
      }
  
      while @char != ']' do
        case @char
          when ':','"',"'" then
            self.advCur
          else
            newKey[:txt] << @char
            self.advCur
            if(@prev_char == '[' && @char ==']') then
              newKey[:txt] << @char
              self.advCur
            end
        end
      end
    end
    @keys << newKey
    self.advCur
  end

  def rewind
    @cur_stack.length <= 0 ? @cur -=1 : @cur = @cur_stack.pop
  end

  def eov?
    return @eov
  end
end

end

#==========================================

module R8Tpl

class IfElsExpressionParser

  attr_accessor :cur,:cur_stack,:expression_string,:length,:prev_char,:char,:next_char,
                :eos,:js_expression_string,:js_var_header,:ctrl_var_mappings,
                :conditional_group_str

  def initialize(expression_string,js_var_header='rtplVars',ctrl_var_mappings=nil)
    @expression_string = expression_string.gsub(/(\if|els\if)\s+/,'')
    @js_expression_string = ''
    @js_var_header = js_var_header
    @cur = 0
    @length = @expression_string.length #public
    @prev_char = ''
    @char = @expression_string[0].chr
    @next_char = ''
    @cur_stack = []
    ctrl_var_mappings.nil? ? @ctrl_var_mappings = [] : @ctrl_var_mappings = ctrl_var_mappings       #private, should probably be passed in constructor

    @eos = false
  end

  def isComplex?
    (@expression_string.include?('(')) ? (return true) : (return false)
  end

  def advCur(num=1)
    while num > 0 do
      if @cur < @length then 
        @cur +=1
      else num = 0 end
      num -=1
    end

    if @cur == @length then
      @eos = true
      return nil
    else
      @prev_char = @char
      @char = @expression_string[@cur].chr
      (@expression_string[@cur+1].nil?) ? @next_char = nil : @next_char = @expression_string[@cur+1].chr
      return @cur
    end
  end

  def to_s
    #change this to return current representation of rendered hash variable
    return @expression_string
  end

  def process
    if(self.isComplex?) then
      #set any leading expression that exists
      leading_expression = ''
      while !self.atExpressionStart?
        leading_expression << @char
        self.advCur
      end
      self.expr2Js(leading_expression)

      self.advCur
      inner_expression_str = self.getInnerExpressionString
      xpression_parser = R8Tpl::IfElsExpressionParser.new(inner_expression_str,@js_var_header,@ctrl_var_mappings)
      xpression_parser.process
      (@js_expression_string != '') ? (@js_expression_string << ' '+xpression_parser.js_expression_string) : (@js_expression_string << xpression_parser.js_expression_string)

      #set any trailing expression that exists
      trailing_expression = ''
      while !self.eos?
        trailing_expression << @char
        self.advCur
      end
      if trailing_expression.include?('(') then
        xpression_parser = R8Tpl::IfElsExpressionParser.new(trailing_expression,@js_var_header,@ctrl_var_mappings)
        xpression_parser.process
        (@js_expression_string != '') ? (@js_expression_string << ' '+xpression_parser.js_expression_string) : (@js_expression_string << xpression_parser.js_expression_string)
      else
        self.expr2Js(trailing_expression)
      end
    else
      self.expr2Js(@expression_string,true)
    end
  end

  def expr2Js(str,wrapExpr=false)
    expression_pieces = str.split(' ')
    expression_pieces.each do |expr|
      if self.isTplVar?(expr) then
        varParser = R8Tpl::TplVarParser.new(expr,@js_var_header,@ctrl_var_mappings)
        varParser.process
        (@js_expression_string != '') ? (@js_expression_string << ' '+varParser.js_var_string) : (@js_expression_string << varParser.js_var_string)
      elsif self.isOperator?(expr)
        (@js_expression_string != '') ? (@js_expression_string << ' '+self.translateOperator(expr)) : (@js_expression_string << self.translateOperator(expr))
      else
        (@js_expression_string != '') ? (@js_expression_string << ' '+expr) : (@js_expression_string << expr)
      end
    end
    if wrapExpr == true then @js_expression_string = '('+@js_expression_string+')' end
  end

  def isOperator?(str)
    case str.strip
      when '==','===','>','<','>=','<=','!=','||','&&' then
        return true
      else
        return false
    end
  end

  def translateOperator(str)
    case str.strip
      when '==','===' then
        return '==='
      when '>','<','>=','<=','!=','||','&&' then
        return str.strip
      else
        return ''
    end
  end

  def isTplVar?(str)
    varRegex = /^[a-zA-Z_@:]/
    (match = varRegex.match(str.strip)) ? (return true) : (return false)
  end

  def atExpressionStart?
    @char == '(' ? (return true) : (return false)
  end

  def getInnerExpressionString
    num_open_expressions = 1
    inner_str = ''
    while num_open_expressions > 0 do
      case @char
        when '(' then
          num_open_expressions +=1
        when ')' then
          num_open_expressions -=1
      end
      if num_open_expressions != 0 then inner_str << @char end
      self.advCur
    end
    return inner_str
  end

  def rewind
    @cur_stack.length <= 0 ? @cur -=1 : @cur = @cur_stack.pop
  end

  def eos?
    return @eos
  end
end

  class TemplateR8ForAction < TemplateR8
    def initialize(js_tpl_name,css_require,js_require) 
      super(nil)
      @js_tpl_callback = js_tpl_name 
      @js_file_name = js_tpl_name+".js" 
      #TBD: canned for testing
       @script = [
          {
           "content" => "var logoutArgs = {\"obj\" : \"user\",\"action\" : \"logout\"};"
          }
       ]
       @cssIncludes = css_require || []
       @errors = []
       @forms = []
       @views = []
       @data = []

       @scriptIncludes = js_require || []
    end
    def ret_result_array()
      
      content = script_includes = nil
      if @js_templating_on
       content = []
       script_includes = @scriptIncludes +
         [{:tplCallback => @js_tpl_callback,
           :src => "js/#{@js_file_name}",
           :templateVars => @template_vars}]
      else
        content = [{:content => @tpl_results, :panel => @panel_set_element_id}]
        script_includes = @scriptIncludes
      end

      {:script => @script,
       :cssIncludes => @cssIncludes,
       :errors => @errors,
       :forms => @forms,
       :views => @views,
       :content => content,
       :data => @data,
       :scriptIncludes => script_includes
      }
    end   
  end 
end
