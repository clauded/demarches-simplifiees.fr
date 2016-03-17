class PieceJustificative < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_de_piece_justificative

  belongs_to :user

  delegate :api_entreprise, :libelle, to: :type_de_piece_justificative

  alias_attribute :type, :type_de_piece_justificative_id

  mount_uploader :content, PieceJustificativeUploader
  validates :content, :file_size => {:maximum => 3.megabytes}

  def empty?
    content.blank?
  end

  def content_url
    unless content.url.nil?
      (Downloader.new content, type_de_piece_justificative.libelle).url
    end
  end
end
