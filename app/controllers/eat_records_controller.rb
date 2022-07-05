class EatRecordsController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery

  def index
    @user = current_user.id
    @eat_records = EatRecord.where(user_id: @user).order(eat_date: "DESC")
  end

  def show
    @eat_record = EatRecord.find(params[:id])
  end

  def new
    @eat_record = EatRecord.new
  end

  def create
    @eat_record = EatRecord.new(eat_record_params)
    @user = current_user.id
    @eat_record.user_id = @user
    if @eat_record.save
      redirect_to @eat_record
    else
      render :new, status: :unprocessable_entitiy
    end
  end

  def edit
    @eat_record = EatRecord.find(params[:id])
  end

  def update
    @eat_record = EatRecord.find(params[:id])

    if @eat_record.update(eat_record_params)
      redirect_to @eat_record
    else
      render :edit, status: :unporcessable_entity
    end
  end

  def destroy
    @eat_record = EatRecord.find(params[:id])
    @eat_record.destroy

    redirect_to root_path, status: :see_other
  end

  def stat
    @user = current_user.id
    @eat_records = EatRecord.where(user_id: @user).order(eat_date: "DESC")
    # @eat_records = EatRecord.select(:id, :shop_name).distinct.where(user_id: @user).order(eat_date: "DESC")
    #@eat_records = EatRecord.select(:shop_name).distinct.where(user_id: @user).order(eat_date: "DESC")
    
    h = Hash.new
    @eat_records.each do |record|
      #logger.debug(record.inspect)
      if h.has_key?(record.shop_name) == false then
        h[record.shop_name] = 1
        #logger.debug("new record added #{record.shop_name}")
        #logger.debug("new record: #{h.inspect}")
      else
        #logger.debug("count up #{h.inspect}")
        count = h[record.shop_name]
        h[record.shop_name] = count.next
      end
    end

    sh = h.sort_by {|_,v| -v}.to_h

    @stats = Array.new
    sh.each do |k,v|
      #logger.debug("key=#{k}, value=#{v}")
      rslt = EatStat.new
      rslt.name = k
      rslt.count = v
      @stats.push(rslt)
    end
  end

  def manifest
    render json: {
      "lang": "ja",
      "name": "EatLog",
      "short_name": "EatLog",
      "start_url": "https://boltech21.net/eat_records",
      "display": "standalone",
      "theme_color": "#0971ac",
      "icons": [{
          "src": "/images/eat-icon.png",
        "sizes": "48x48",
        "type": "image/png"
      }, {
          "src": "/images/eat-icon.png",
        "sizes": "72x72",
        "type": "image/png"
      }, {
          "src": "/images/eat-icon.png",
        "sizes": "96x96",
        "type": "image/png"
      }, {
          "src": "/images/eat-icon.png",
        "sizes": "144x144",
        "type": "image/png"
      },{
          "src": "/images/eat-icon.png",
        "sizes": "192x192",
        "type": "image/png"
      }]
    }
  end

  def map

  end

  private
    def eat_record_params
      params.require(:eat_record).permit(:shop_name, :place_name, :usecase, :eat_with, :eat_date, :eat_time, :eat_menu, :article)
    end
end
