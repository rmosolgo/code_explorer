

class Code
	include MongoMapper::Document
	
	key :code,		String
	key :name,		String
	key :parent,	String
	key :children, 	Array
	key :type,		String
	timestamps!

	validate :unique_and_valid_code
	validate :all_children_are_present

	def unique_and_valid_code
		if code =~ /[0-9\.]+/ && Code.find({ code: code}) == nil
			p 'Valid and Unique'
			return true
		else 
			p 'Not Valid and Unique'
			return false
		end
	end
	def all_children_are_present
		children.each do |c| 
			if Code.find({code: c}).count != 1
				"Child #{c} is not present"
				return false
			end
		end
		p "All Children are present"
		return true
	end

	def serializable_hash(options = {})
    	super({:except => [:id, :new, :_id, :_new, :changed_attributes], methods: [:all_children]}.merge(options))
 	end

 	def to_yaml
 		serializable_hash.to_yaml
 	end

 	def all_children
 		count = 0
 		if children.class == Array 
 			count += children.count
 			children.map do |c|
 				if c.class == String &&code = Code.first({code: c})
 					count += code.all_children
 				end
 			end
 		end
 		count
 	end


 	def with_nested_children
 		new_object = self.clone
 		new_object.children = children.map do |c|
 			Code.first({code: c})
 		end
 		return new_object
 	end


end
	
