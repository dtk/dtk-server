#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# TODO: modify so that types like port can call tehir parents methods
module DTK; class Attribute
  class SemanticDatatype
    Type :object do
      basetype :json
    end
    Type :array do
      basetype :json
      validation lambda { |v| v.is_a?(Array) }
    end
    Type :hash do
      basetype :json
      validation lambda { |v| v.is_a?(Hash) }
    end
    Type :port do
      basetype :integer
      validation /^[0-9]+$/
      internal_form lambda { |v| v.to_i }
    end
    Type :log_file do
      basetype :string
      validation /.*/ #so checks that it is scalar
    end

    Type :node_template_type do
      basetype :string
      validation /.*/ #TODO: put validation in here; may need a handle in appropriate place in object model to see what is valid
    end

    # base types
    Type :string do
      basetype :string
      validation /.*/ #so checks that it is scalar
    end
    Type :integer do
      basetype :integer
      validation /^[0-9]+$/
      internal_form lambda { |v| v.to_i }
    end
    Type :boolean do
      basetype :boolean
      validation /true|false/
      internal_form lambda{|v|
        if v.is_a?(TrueClass) || v == 'true'
          true
        elsif v.is_a?(FalseClass) || v == 'false'
          false
        else
          fail Error.new("Bad boolean type (#{v.inspect})") #this should not be reached since v is validated before this fn called
        end
      }
    end
    # TODO: may deprecate
    Type :json do
      basetype :json
    end
  end
end; end