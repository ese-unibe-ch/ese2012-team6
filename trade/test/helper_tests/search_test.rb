require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../../app/models/store/item'
require_relative '../../app/models/store/user'
require_relative '../../app/models/helpers/storage/search'
class SearchTest < Test::Unit::TestCase
  include Store
  include Storage
  def setup
    (user_admin = User.named("admin")).save
    (user_ese = User.named("ese")).save
    (user_ese2 = User.named("ese2")).save
    (user_ese3 = User.named("ese3")).save
    (user_ese4 = User.named("ese4")).save
    (user_ese5 = User.named("ese5")).save
    (user_ese6 = User.named("ese6")).save
    (user_ese7 = User.named("ese7")).save
    (user_ese8 = User.named("ese8")).save
    (user_ese9 = User.named("ese9")).save
    (user_ese10 = User.named("ese10")).save
    (umbrella_corp = User.named("umbrellacorp")).save
    (peter_griffin = User.named("petergriffin")).save

    #add default items
    (@liver = user_ese.propose_item("Liver", 40, "auction", 5, "2013-11-11 20:00:00")).activate
    (@heart = umbrella_corp.propose_item("Heart", 80, "fixed", nil, nil)).activate
    (@meg = user_ese2.propose_item_with_quantity("Meg", 2, 4, "fixed", nil, nil, "This is a description")).activate
    @random = umbrella_corp.propose_item("Random", 50, "fixed", nil, nil)
    (@bender = umbrella_corp.propose_item("Bender", 110, "fixed", nil, nil)).activate
  end

  def test_name_search
    matched_items = Search.search("Liver")
    assert(matched_items.include?(@liver))
    assert(matched_items.length, 1)

    matched_items = Search.search("er")
    assert(matched_items.include?(@liver))
    assert(matched_items.include?(@bender))
    assert(matched_items.length, 2)
  end

  def test_case_insensitive
    matched_items = Search.search("LiVeR")
    assert(matched_items.include?(@liver))
    assert(matched_items.length, 1)

    matched_items = Search.search("Er")
    assert(matched_items.include?(@liver))
    assert(matched_items.include?(@bender))
    assert(matched_items.length, 2)
  end

  def test_description_search
    matched_items = Search.search("This is")
    assert(matched_items.include?(@meg))
    assert(matched_items.length, 1)
  end

end