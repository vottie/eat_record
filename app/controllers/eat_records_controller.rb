class EatRecordsController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery

  def index
    @user = current_user.id
    @eat_records = EatRecord.where(user_id: @user).order(eat_date: "DESC").page(params[:page])
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
    @stats = Array.new
    
    # Count the number of occurrences of each element in the array.
    records = Array.new
    @eat_records.each do |record|
      records.push(record.shop_name)
    end
    counts = records.tally

    sort_counts = counts.sort_by { |key, value| value }.reverse
    sort_counts.each { |key, value| 
      # logger.debug("#{key} : #{value}")
      stat = EatStat.new
      stat.name = key
      stat.count = value
      @stats.push(stat)
    }
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

  private
    def eat_record_params
      params.require(:eat_record).permit(:shop_name, :place_name, :usecase, :eat_with, :eat_date, :eat_time, :eat_menu, :article)
    end
end
