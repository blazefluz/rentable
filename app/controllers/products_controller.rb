# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy, :availability]

  # GET /products
  def index
    @products = Product.active
                      .search(params[:query])
                      .by_category(params[:category])
                      .order(created_at: :desc)
                      .page(params[:page])

    @categories = Product.active.pluck(:category).compact.uniq.sort
  end

  # GET /products/:id
  def show
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.tomorrow
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : @start_date + 3.days

    @available_quantity = @product.available_quantity(@start_date, @end_date)
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/:id/edit
  def edit
  end

  # POST /products
  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to @product, notice: "Product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /products/:id
  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /products/:id
  def destroy
    @product.update(active: false)
    redirect_to products_url, notice: "Product was successfully archived."
  end

  # GET /products/:id/availability
  def availability
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : start_date + 7.days

    checker = AvailabilityChecker.new(@product, start_date, end_date)

    render json: {
      available_quantity: checker.available_quantity,
      availability_by_date: checker.availability_by_date
    }
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name, :description, :category, :barcode,
      :daily_price_cents, :daily_price_currency,
      :quantity, :active, serial_numbers: [], images: []
    )
  end
end
