require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/item'
require_relative '../app/models/store/user'
require_relative '../app/models/store/offer'

class ItemTest < Test::Unit::TestCase
  include Store

  def before
    Item.clear_all
  end

  # Creates an offer and checks whether the setters and getters are working correctly
  def test_offer_variables
    user = User.named("Hans")
    offer = Offer.create("Beer",20,5,user)

    assert offer.from.eql? user
    assert offer.item_name == "Beer"
    assert offer.price == 20
    assert offer.quantity == 5
  end

  def test_user
    Offer.all.each {|offer| offer.delete}
    user = User.named("Hans")
    offer = Offer.create("Beer",3,8,user)
    offer2 = Offer.create("Aspirin",20,1,user)
    offer.save
    offer2.save

    assert Offer.by_id(offer.id).eql? offer
    assert Offer.by_id(offer2.id).eql? offer2
    assert Offer.all.size ==2


  end

  # Checks whether the item has the correct price
  def test_item_price
    item_price = 555
    item = Item.fixed("TestItem", item_price, nil)
    assert_equal(item_price, item.price)
  end


end