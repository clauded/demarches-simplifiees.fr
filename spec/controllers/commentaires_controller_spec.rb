require 'spec_helper'

describe Users::CommentairesController, type: :controller do
  let(:dossier) { create(:dossier, :with_user) }
  let(:dossier_id) { dossier.id }
  let(:email_commentaire) { 'test@test.com' }
  let(:texte_commentaire) { 'Commentaire de test' }

  describe '#POST create' do
    context 'création correct d\'un commentaire' do
      it 'depuis la page récapitulatif' do
        sign_in dossier.user
        post :create, dossier_id: dossier_id, texte_commentaire: texte_commentaire
        expect(response).to redirect_to("/users/dossiers/#{dossier_id}/recapitulatif")
      end
    end

    describe 'change dossier state after post a comment' do
      context 'when user is connected' do
        context 'when dossier is at state reply' do
          before do
            sign_in dossier.user
            dossier.reply!

            post :create, dossier_id: dossier_id, texte_commentaire: texte_commentaire
            dossier.reload
          end

          subject { dossier.state }

          it {is_expected.to eq('updated')}
        end
      end
    end
  end
end
