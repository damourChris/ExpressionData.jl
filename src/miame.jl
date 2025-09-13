import Base.==

"""
    MIAME

An `MIAME` object is a container for storing metadata associated with an experiment.
It follows the `MIAME` class from the R package from Bioconductor: `Biobase`.

# See also
[`abstract`](@ref)
[`info`](@ref)
[`hybridizations`](@ref)
[`norm_controls`](@ref)
[`other`](@ref)
[`preprocessing`](@ref)
[`pub_med_id`](@ref)
"""
@kwdef struct MIAME
    name::String
    lab::String
    contact::String
    title::String
    abstract::String
    url::String
    pub_med_id::String
    samples::Vector{String}
    hybridizations::Vector{String}
    norm_controls::Vector{String}
    preprocessing::Vector{String}
    other::Dict{Symbol,String}
end

function Base.show(io::IO, mime::MIME"text/plain", miame::MIAME)
    println(io, "MIAME Information:")
    println(io, "------------------")

    # Display name and lab
    println(io, "\nName: $(miame.name)")
    println(io, "Lab: $(miame.lab)")

    # Display contact information
    println(io, "\nContact:")
    println(io, "  Name: $(miame.contact)")
    println(io, "  Title: $(miame.title)")

    # Display abstract
    println(io, "\nAbstract:")
    println(io, "$(miame.abstract)")

    # Display URL and PubMed ID
    println(io, "\nAdditional Information:")
    println(io, "  URL: $(miame.url)")
    println(io, "  PubMed ID: $(miame.pub_med_id)")

    # Display other information
    if !isempty(miame.other)
        println(io, "\nOther Information:")
        for (key, value) in miame.other
            println(io, "  $key: $(value)")
        end
    end
end

function ==(m1::MIAME, m2::MIAME)
    return m1.name == m2.name &&
           m1.lab == m2.lab &&
           m1.contact == m2.contact &&
           m1.title == m2.title &&
           m1.abstract == m2.abstract &&
           m1.url == m2.url &&
           m1.pub_med_id == m2.pub_med_id &&
           m1.samples == m2.samples &&
           m1.hybridizations == m2.hybridizations &&
           m1.norm_controls == m2.norm_controls &&
           m1.preprocessing == m2.preprocessing &&
           m1.other == m2.other
end

"""
    abstract(m::MIAME)::String

Extracts the abstract from an MIAME object.
"""
abstract(m::MIAME) = m.abstract

"""
    info(m::MIAME)::NamedTuple

Returns a `NamedTuple` with the name, lab, contact, title, and url fields of an MIAME object.
Similar to the `expinfo` function in the R package from Bioconductor: `Biobase`.
"""
function info(m::MIAME)
    return (; name=m.name,
            lab=m.lab,
            contact=m.contact,
            title=m.title,
            url=m.url)
end

"""
    hybridizations(m::MIAME)::Vector{String}

Extracts the hybridizations from an MIAME object.
"""
hybridizations(m::MIAME) = m.hybridizations

"""
    norm_controls(m::MIAME)::Vector{String}

Extracts the normalization controls from an MIAME object such as house keeping genes.
"""
norm_controls(m::MIAME) = m.norm_controls

"""
    other(m::MIAME)::Dict{Symbol,String}

Extracts the other metadata from an MIAME object. This can include any additional information
that is not covered by the other fields.

"""
other(m::MIAME) = m.other
notes(m::MIAME) = other(m)

"""
    preprocessing(m::MIAME)::Vector{String}

Extracts the preprocessing steps from an MIAME object describe the steps taken to process the raw data of the experiment.
"""
preprocessing(m::MIAME) = m.preprocessing

"""
    pub_med_id(m::MIAME)::String

Extracts the pubmed id from an MIAME object.
"""
pub_med_id(m::MIAME) = m.pub_med_id

import Base.merge
function merge(m1::MIAME, m2::MIAME)
    new_name = m1.name * m2.name
    new_lab = m1.lab * m2.lab
    new_contact = m1.contact * m2.contact
    new_title = m1.title * m2.title
    new_abstract = m1.abstract * m2.abstract
    new_url = m1.url * m2.url
    new_samples = vcat(m1.samples, m2.samples)

    new_hybridizations = vcat(m1.hybridizations, m2.hybridizations)
    new_norm_controls = vcat(m1.norm_controls, m2.norm_controls)
    new_preprocessing = vcat(m1.preprocessing, m2.preprocessing)
    new_pub_med_id = m1.pub_med_id * m2.pub_med_id
    new_other = merge(m1.other, m2.other)

    return MIAME(;
                 name=new_name,
                 lab=new_lab,
                 contact=new_contact,
                 title=new_title,
                 abstract=new_abstract,
                 url=new_url,
                 samples=new_samples,
                 hybridizations=new_hybridizations,
                 norm_controls=new_norm_controls,
                 preprocessing=new_preprocessing,
                 pub_med_id=new_pub_med_id,
                 other=new_other)
end

# Note: R interoperability functions have been moved to ExpressionDataInterop.jl
