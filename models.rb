

class Code
	include MongoMapper::Document
	
	key :code,		String
	key :name,		String
	key :parent,	String
	key :children, 	Array
	key :type,		String
	key :all_children, Integer
	timestamps!

	validate :unique_and_valid_code
	validate :all_children_are_present
	before_save :sort_children
	after_save :set_parent_all_children
	after_save :save_static_files

	def sort_children
		children.sort!
	end

	def set_parent_all_children
		if p = Code.find(code: self.parent)
			p.set_all_children!
		end
	end

	def unique_and_valid_code
		if code =~ /[0-9\.]+/ && Code.find({ code: code}) == nil
			return true
		else 
			p 'Not Valid and Unique'
			return false
		end
	end
	def all_children_are_present
		children.each do |c| 
			if Code.all({code: c}).count != 1
				"Child #{c} is not present"
				return false
			end
		end
		return true
	end

	def serializable_hash(options = {})
    	super({:except => [:id, :new, :_id, :_new, :changed_attributes]}.merge(options))
 	end

 	def to_yaml
 		serializable_hash.to_yaml
 	end

 	def set_all_children!
 		count = 0
 		if children.class == Array 
 			count += children.count
 			children.map do |c|
 				if c.class == String && code = Code.first({code: c})
 					code.set_all_children!
 					count += code.all_children || 0
 				end
 			end
 		end
 		all_children = count
 		save
 	end


 	def with_nested_children
 		new_object = self.clone
 		new_object.children = children.map do |c|
 			Code.first({code: c})
 		end
 		return new_object
 	end


 	def build_one_object
 		root = Code.first(parent: nil)
 		root_with_children = root.with_nested_children
 		root_with_children.children.each do |c|
 			c.children = c.with_nested_children.children
 		end
 	end

 	def with_all_nested_children
 		new_object = self.clone.with_nested_children
 		new_object.children = new_object.children.map do |c|
 			if c && c.children && c.children.class == Array && c.children.length >0
 				c.with_all_nested_children
 			else
 				c
 			end
 		end
 		return new_object
 	end


 	def save_static_files
 		f = open('public/code_tree.json', 'w+')
		f.write(Code.first(code: '0').with_all_nested_children.to_json)
		f.close

		require 'csv'
		CSV.open("public/codes.csv", "wb") do |csv|
			csv << ["code", "name", "parent", "children", "all_children_count"]
			Code.all.each do |code|
			  csv << [code.code, code.name, code.parent, (code.children ? code.children.join(",") : ""), all_children]
			end
		end
	end

end
	
