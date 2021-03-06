require File.dirname(__FILE__) + '/../spec_helper.rb'

describe ProjectList do
  describe "creation" do
    it "should set defaults" do
      p = Project.make!
      pl = p.project_list
      expect( pl ).to be_valid
      expect( pl.title ).to_not be_blank
      expect( pl.description ).to_not be_blank
    end
  end
end

describe ProjectList, "refresh_with_observation" do
  before { enable_elastic_indexing(Observation) }
  after { disable_elastic_indexing(Observation) }

  it "should not remove taxa with no more confirming observations" do
    p = Project.make!
    pl = p.project_list
    t1 = Taxon.make!
    t2 = Taxon.make!
    o = make_research_grade_observation(taxon: t1)
    
    pu = ProjectUser.make!(user: o.user, project: p)
    po = ProjectObservation.make!(project: p, observation: o, user: o.user)
    ProjectList.refresh_with_observation(o)
    pl.reload
    expect( pl.taxon_ids ).to_not include( o.taxon_id )
    o = Observation.find(o.id)
    o.update_attributes(taxon: t2)
    i = Identification.make!(observation: o, taxon: t2)
    Observation.set_quality_grade(o.id)
    o.reload
    
    ProjectList.refresh_with_observation(o, taxon_id: o.taxon_id,
      taxon_id_was: t1.id, user_id: o.user_id, created_at: o.created_at)
    pl.reload
    expect( pl.taxon_ids ).to_not include( t1.id )
    expect( pl.taxon_ids ).to_not include( t2.id )
  end
  
  it "should not add taxa from research grade observations added to the project" do
    p = Project.make!
    pl = p.project_list
    t1 = Taxon.make!(rank: Taxon::SPECIES)
    o = make_research_grade_observation(taxon: t1)
    pu = ProjectUser.make!(user: o.user, project: p)
    po = ProjectObservation.make!(project: p, observation: o)
    Delayed::Worker.new(quiet: true).work_off
    pl.reload
    expect( pl.taxon_ids ).to_not include( o.taxon_id )
  end
  
  it "should not add taxa to project list from project observations made by curators" do
    p = Project.make!
    pu = without_delay {ProjectUser.make!(project: p, role: ProjectUser::CURATOR)}
    t = Taxon.make!
    o = Observation.make!(user: pu.user, taxon: t)
    po = without_delay {make_project_observation(observation: o, project: p, user: o.user)}
    
    expect( po.curator_identification_id ).to eq( o.owners_identification.id )
    cid_taxon_id = Identification.find_by_id(po.curator_identification_id).taxon_id
    pl = p.project_list
    expect( pl.taxon_ids ).to_not include( cid_taxon_id )
  end
  
  it "should confirm a species when a subspecies was observed" do
    species = Taxon.make!(rank: "species")
    subspecies = Taxon.make!(rank: "subspecies", parent: species)
    p = Project.make!
    pl = p.project_list
    lt = pl.add_taxon(species, user: p.user, manually_added: true)
    po = make_project_observation_from_research_quality_observation(project: p, taxon: subspecies)
    Delayed::Worker.new(quiet: true).work_off
    lt.reload
    expect( lt.last_observation ).to eq( po.observation )
  end
  
  it "should not add taxa observed by project curators on reload" do
    p = Project.make!
    pu = without_delay {ProjectUser.make!(project: p, role: ProjectUser::CURATOR)}
    t = Taxon.make!
    o = Observation.make!(user: pu.user, taxon: t)
    po = without_delay {make_project_observation(observation: o, project: p, user: o.user)}
    
    expect( po.curator_identification_id ).to eq( o.owners_identification.id )
    cid_taxon_id = Identification.find_by_id(po.curator_identification_id).taxon_id
    pl = p.project_list
    expect( pl.taxon_ids ).to_not include( cid_taxon_id )
    lt.destroy if lt = ListedTaxon.where(list_id: pl.id, taxon_id: cid_taxon_id).first
    expect( pl.taxon_ids ).to_not include( cid_taxon_id )
  end
end

describe ProjectList, "refresh_with_project_observation" do
  it "does not fail if given nil project_observation" do
    p = Project.make!
    o = Observation.make!
    expect{
      ProjectList.refresh_with_project_observation( nil, { observation_id: o.id, project_id: p.id } )
    }.to_not raise_error
  end

  it "does not fail if given missing project_observation" do
    p = Project.make!
    o = Observation.make!
    expect{
      ProjectList.refresh_with_project_observation( 999, { observation_id: o.id, project_id: p.id } )
    }.to_not raise_error
  end
end
