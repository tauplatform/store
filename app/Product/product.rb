# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Product
  include Rho::ORM::PropertyBag
  enable :sync
  
  #enable :full_update
end
