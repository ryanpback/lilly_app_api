class ImagesController < ApplicationController
  def create
    iv = ImageValidator.validate!(params: params)

    return render json: { error: iv.error }, status: iv.status if iv.error

    bucket      = @current_user.bucket
    gcs_service = GcsManagementService.new(bucket.id)
    filename    = gcs_service.upload_file(file: params[:lilly_app_upload])
    image       = BucketService.new(bucket).save_image!(filename: filename)

    if image.valid?
      render json: { message: 'File successfully saved' }, status: :created
    else
      render json: { error: image.errors.to_hash(true) }, status: :conflict
    end
  rescue GcsManagementService::BucketExistsError
    render json: { error: 'Storage location already exists.' }, status: :conflict
  end

  def show; end

  def destroy; end
end
