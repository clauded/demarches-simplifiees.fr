require 'spec_helper'

describe Procedure do
  describe 'assocations' do
    it { is_expected.to have_many(:types_de_piece_justificative) }
    it { is_expected.to have_many(:types_de_champ) }
    it { is_expected.to have_many(:dossiers) }
    it { is_expected.to have_one(:module_api_carto) }
    it { is_expected.to belong_to(:administrateur) }
  end

  describe 'attributes' do
    it { is_expected.to have_db_column(:libelle) }
    it { is_expected.to have_db_column(:description) }
    it { is_expected.to have_db_column(:organisation) }
    it { is_expected.to have_db_column(:direction) }
    it { is_expected.to have_db_column(:test) }
    it { is_expected.to have_db_column(:euro_flag) }
    it { is_expected.to have_db_column(:logo) }
    it { is_expected.to have_db_column(:logo_secure_token) }
    it { is_expected.to have_db_column(:cerfa_flag) }
  end

  describe 'validation' do
    context 'libelle' do
      it { is_expected.not_to allow_value(nil).for(:libelle) }
      it { is_expected.not_to allow_value('').for(:libelle) }
      it { is_expected.to allow_value('Demande de subvention').for(:libelle) }
    end

    context 'description' do
      it { is_expected.not_to allow_value(nil).for(:description) }
      it { is_expected.not_to allow_value('').for(:description) }
      it { is_expected.to allow_value('Description Demande de subvention').for(:description) }
    end

    context 'lien_demarche' do
      it { is_expected.to allow_value(nil).for(:lien_demarche) }
      it { is_expected.to allow_value('').for(:lien_demarche) }
      it { is_expected.to allow_value('http://localhost').for(:lien_demarche) }
    end
  end

  describe '#types_de_champ_ordered' do
    let(:procedure) { create(:procedure) }
    let!(:type_de_champ_0) { create(:type_de_champ, procedure: procedure, order_place: 1) }
    let!(:type_de_champ_1) { create(:type_de_champ, procedure: procedure, order_place: 0) }
    subject { procedure.types_de_champ_ordered }
    it { expect(subject.first).to eq(type_de_champ_1) }
    it { expect(subject.last).to eq(type_de_champ_0) }
  end

  describe '#switch_types_de_champ' do
    let(:procedure) { create(:procedure) }
    let(:index) { 0 }
    subject { procedure.switch_types_de_champ index }

    context 'when procedure have no types_de_champ' do
      it { expect(subject).to eq(false) }
    end
    context 'when procedure have 2 types de champ' do
      let!(:type_de_champ_0) { create(:type_de_champ, procedure: procedure, order_place: 0) }
      let!(:type_de_champ_1) { create(:type_de_champ, procedure: procedure, order_place: 1) }
      context 'when index is not the last element' do
        it { expect(subject).to eq(true) }
        it 'switch order place' do
          procedure.switch_types_de_champ index
          type_de_champ_0.reload
          type_de_champ_1.reload
          expect(type_de_champ_0.order_place).to eq(1)
          expect(type_de_champ_1.order_place).to eq(0)
        end
      end
      context 'when index is the last element' do
        let(:index) { 1 }
        it { expect(subject).to eq(false) }
      end
    end
  end

  describe 'locked?' do
    let(:procedure) { create(:procedure, published: published) }

    subject { procedure.locked? }

    context 'when procedure is in draft status' do
      let(:published) { false }
      it { is_expected.to be_falsey }
    end

    context 'when procedure is in draft status' do
      let(:published) { true }
      it { is_expected.to be_truthy }
    end
  end

  describe 'active' do
    let(:procedure) { create(:procedure, published: published, archived: archived) }
    subject { Procedure.active(procedure.id) }

    context 'when procedure is in draft status and not archived' do
      let(:published) { false }
      let(:archived) { false }
      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'when procedure is published and not archived' do
      let(:published) { true }
      let(:archived) { false }
      it { is_expected.to be_truthy }
    end

    context 'when procedure is published and archived' do
      let(:published) { true }
      let(:archived) { true }
      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'when procedure is in draft status and archived' do
      let(:published) { false }
      let(:archived) { true }
      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
