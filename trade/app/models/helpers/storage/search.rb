module Storage
  #Allows user to look for an item
  class Search

    #Returns all items, which match the input of the user.
    def self.search(description)

      items = Store::Item.all.select{|item| item.state != :pending}
      pattern = "(?i)(\w+)?(#{description})(\w+)?"
      begin
        return items.select {|x| x.description.match(pattern) or x.name.match(pattern)}
      rescue Exception
        return []
      end
    end
  end
end