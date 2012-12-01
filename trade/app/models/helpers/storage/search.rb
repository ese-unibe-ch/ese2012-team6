class Search

  def self.search(description)
    items = Store::Item.all
    pattern = "(\w+)?#{description}(\w+)?"
    items.select {|x| x.description.match(pattern) or x.name.match(pattern)}
  end

end