#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'

# Collection of Model methods.
#
# @since 2.0.0
module TT::Model
  
  # Version safe +model.start_operation+ wrapper.
	#
	# @param [String] name
	# @param [Sketchup::Model] model - defaults to active model.
  #
	# @return [Boolean]
	# @since 2.0.0
  def self.start_operation(name, model = Sketchup.active_model)
    if TT::SketchUp.version[0] >= 7
      model.start_operation(name, true)
    else
      model.start_operation(name)
    end
  end
  
  
  # Counts all unique +Sketchup::Entities+ collections in the given model,
  # excluding Image definitions.
  #
  # @param [Sketchup::Model] model
  # @param [Boolean] only_used_definitions
  #
	# @return [Integer]
	# @since 2.5.0
  def self.count_unique_entities( context, only_used_definitions=true )
    if only_used_definitions
      model.definitions.reject { |d| d.image? || d.count_instances == 0 }.length + 1
    else
      model.definitions.reject { |d| d.image? }.length + 1
    end
  end
  
  
  # Counts all unique entities in the given model, including sub-entities.
  #
  # @param [Sketchup::Model] model
  # @param [Boolean] only_used_definitions
  #
	# @return [Integer]
	# @since 2.5.0
  def self.count_unique_entity( model, only_used_definitions=true )
    c = model.entities.length
    for d in model.definitions
      next if d.image?
      next if only_used_definitions && d.count_instances == 0
      c += d.entities.count
    end
    c
  end
  
  
  # Yields each unique Entities collection recursivly.
  #
  #  TT::Model.each_entities { |entities|
  #    processEntities( entities )
  #  }
  #
  # If a number is returned to the processing block it will be used to add up a
  # total when +each_entities+ returns.
  #
  #  TT::Model.each_entities { |entities|
  #    c = 0
  #    for e in entities
  #      c += 1 if e.is_a?( SketchUp::Edge )
  #    end
  #    c
  #  }
  #
  # This example will return the total number of edges processed. Use to keep
  # statistic for the iteration.
  #
  # @param [Sketchup::Model] model
  # @param [Boolean] only_used_definitions
  #
  # @yield [entities]
	# @yieldparam [Enumerable|Sketchup::Entities] entities
  #
	# @return [Integer] Returns
	# @since 2.5.0
  def self.each_entities( model, only_used_definitions=true )
    c = 0
    result = yield( model.entities )
    c += result if result.is_a?( Numeric )
    for d in model.definitions
      next if d.image?
      next if only_used_definitions && d.count_instances == 0
      result += yield( d.entities )
      c += result if result.is_a?( Numeric )
    end
    c
  end
  
  
  # Yields all the entities in the model. Note that it does not traverse the 
  # model hierarchy.
  #
  # When +only_used_definitions+ is true, only entities that is used in the model
  # is yielded. When +only_used_definitions+ is false, also the entiites in
  # unused definitions are yielded.
	#
	# @param [Sketchup::Model] model
	# @param [Boolean] only_used_definitions
  #
  # @yield [entity]
	# @yieldparam [Sketchup::Entity] entity
  #
	# @return [Integer] Number of entities which returned non-false.
	# @since 2.5.0
  def self.each_entity( model, only_used_definitions=true )
    # c = c.next is faster than c += 1
    # http://forums.sketchucation.com/viewtopic.php?f=180&t=25305&p=305810#p305810
    c = 0
    for e in model.entities.to_a
      c = c.next if yield( e )
    end
    for d in model.definitions
      next if d.image?
      next if only_used_definitions && d.count_instances == 0
      for e in d.entities.to_a
        c = c.next if yield( e )
      end
    end
    c
  end
  
end # module TT::Model