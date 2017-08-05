module Traits
export has_axis, is_spin_polarized, Polarized, Unpolarized, components
export PolarizationCategory, FunctionalCategory, LDA, GGA

using DocStringExtensions
using AxisArrays
using Unitful
using ..UnitfulHartree
using ..Dispatch
const DD = Dispatch.Dimensions

macro lintpragma(s) end
@lintpragma("Ignore use of undeclared variable D")
@lintpragma("Ignore use of undeclared variable unitful_dimensions")

const UH = UnitfulHartree

has_axis(array::Type{<:AxisArray}, axis::Type{<:Axis}) =
    axisnames(axis)[1] ∈ axisnames(array)
has_axis(a::AxisArray, axis_type::Type{<:Axis}) = has_axis(typeof(a), axis_type)
has_axis(array::Type{<:AxisArray}, name::Symbol) = has_axis(array, Axis{name})
has_axis(a::AxisArray, name::Symbol) = has_axis(typeof(a), name)
    

"""
True if the array is spin polarized, meaning it has an axis named `:spin` with two values

$(SIGNATURES)

Note that if the argument is a type (rather than an instance) then the values of the spin
axis should be a tuple, e.g.:

`typeof(Axis(:spin, (:+, :-))) === Axis{:spin, Tuple{Symbol, Symbol}}`
"""
is_spin_polarized(array::AxisArray) = begin
    has_axis(array, Axis{:spin}) || return false
    vals = axisvalues(axes(array, Axis{:spin}))[1]
    return length(vals) == 2
end

is_spin_polarized(array::Type{<: AxisArray}) = begin
    index = findfirst(axisnames(array), :spin)
    index == 0 && return false
    axis = array.parameters[end].parameters[index]
    length(axis.parameters[2].parameters) == 2
end

""" Trait for functions accepting polarized inputs """
const Polarized = Val{:Polarized}
""" Trait for functions accepting unpolarized inputs """
const Unpolarized = Val{:Unpolarized}
""" Union of al polarization traits """
const PolarizationCategory = Union{Polarized, Unpolarized}
""" Figures whether input is polarized or not """
@generated (::Type{PolarizationCategory})(array::AxisArray) =
    is_spin_polarized(array) ? :(Polarized()) : :(Unpolarized())

""" Trait identifying the LDA functional category """
const LDA = Val{:lda}
""" Trait identifying the LDA functional category """
const GGA = Val{:gga}
""" Union of all functional categories """
const FunctionalCategory = Union{LDA, GGA}

"""
Same as Unitful.dimension but for still abstract quantities
"""
unitful_dimensions(::Type{<: Quantity{T, D, U} where {U, T}}) where D = D()

"""
Figures out functional category, whether LDA or GGA

$(SIGNATURES)
"""
(::Type{FunctionalCategory})(::typeof(dimension(UH.ρ))) = LDA
(::Type{FunctionalCategory})(::typeof(dimension(UH.∂ϵ_∂ρ))) = LDA
(::Type{FunctionalCategory})(::typeof(dimension(UH.∂²ϵ_∂ρ²))) = LDA
(::Type{FunctionalCategory})(::typeof(dimension(UH.∂³ϵ_∂ρ³))) = LDA
(::Type{FunctionalCategory})(::typeof(dimension(UH.σ))) = GGA
(::Type{FunctionalCategory})(::typeof(dimension(UH.∂ϵ_∂σ))) = GGA
(::Type{FunctionalCategory})(::typeof(dimension(UH.∂²ϵ_∂ρ∂σ))) = GGA
(::Type{FunctionalCategory})(::typeof(dimension(UH.∂²ϵ_∂σ²))) = GGA
(::Type{FunctionalCategory})(::typeof(dimension(UH.∂³ϵ_∂ρ²∂σ))) = GGA
(::Type{FunctionalCategory})(::typeof(dimension(UH.∂³ϵ_∂ρ∂σ²))) = GGA
(::Type{FunctionalCategory})(::typeof(dimension(UH.∂³ϵ_∂σ³))) = GGA
(::Type{FunctionalCategory})(u::Unitful.FreeUnits) = FunctionalCategory(dimension(u))
(::Type{FunctionalCategory})(u::DD.Scalars.All) = FunctionalCategory(dimension(u))
(::Type{FunctionalCategory})(T::Type{<: DD.Scalars.All}) =
    FunctionalCategory(unitful_dimensions(T))

"""
Labels of the standard components for LDA and GGA inputs

$(SIGNATURES)

ρ refers to the unpolarized density, α and β to the two spin channels of the density, σ to
the contracted gradient density (∇ρ⋅∇ρ), and σαα (∇α⋅∇α), σαβ, σββ  to the polarized
contracted gradient densities.
"""
components(::typeof(dimension(UH.ρ)), ::Unpolarized) = (:ρ,)
components(::typeof(dimension(UH.∂ϵ_∂ρ)), ::Unpolarized) = (:∂ρ,)
components(::typeof(dimension(UH.∂²ϵ_∂ρ²)), ::Unpolarized) = (:∂ρ²,)
components(::typeof(dimension(UH.∂³ϵ_∂ρ³)), ::Unpolarized) = (:∂ρ³,)
components(::typeof(dimension(UH.ρ)), ::Polarized) = :α, :β
components(::typeof(dimension(UH.∂ϵ_∂ρ)), ::Polarized) = :∂α, :∂β
components(::typeof(dimension(UH.∂²ϵ_∂ρ²)), ::Polarized) = :∂α², :∂α∂β, :∂²β 
components(::typeof(dimension(UH.∂³ϵ_∂ρ³)), ::Polarized) = :∂α³, :∂α∂β², :∂α∂β², :∂β³
components(::typeof(dimension(UH.σ)), ::Polarized) = :σαα, :σαβ, :σββ
components(::typeof(dimension(UH.∂ϵ_∂σ)), ::Polarized) = :∂σαα, :∂σαβ, :∂σββ
components(::typeof(dimension(UH.∂²ϵ_∂ρ∂σ)), ::Polarized) = 
    :∂α∂σαα, :∂α∂σαβ, :∂α∂σββ, :∂β∂σαα, :∂β∂σαβ, :∂β∂σββ
components(::typeof(dimension(UH.∂²ϵ_∂σ²)), ::Polarized) =
    :∂σαα², :∂σαα∂σαβ, :∂σαα∂σββ, :∂σαβ², :∂σαβσββ, :∂σββ² 
components(::typeof(dimension(UH.∂³ϵ_∂ρ²∂σ)), ::Polarized) = (
    :∂α²∂σαα, :∂α²∂σαβ, :∂α²∂σββ,
    :∂α∂β∂σαα, :∂α∂β∂σαβ, :∂α∂β∂σββ,
    :∂β²∂σαα, :∂β²∂σαβ, :∂β²∂σββ
)
components(::typeof(dimension(UH.∂³ϵ_∂ρ∂σ²)), ::Polarized) = (
    :∂α∂σαα², :∂α∂σαα∂σαβ, :∂α∂σαα∂σββ, :∂α∂σαβ², :∂α∂σαβσββ, :∂α∂σββ²,
    :∂β∂σαα², :∂β∂σαα∂σαβ, :∂β∂σαα∂σββ, :∂β∂σαβ², :∂β∂σαβσββ, :∂β∂σββ² 
)
components(::typeof(dimension(UH.∂³ϵ_∂σ³)), ::Polarized) = (
    :∂σαα³, :∂σαα²∂σαβ, :∂σαα²∂σββ, :∂σαα∂σαβ², :∂σαα∂σαβ∂σββ, :∂σαα∂σββ², 
    :∂σαβ³, :∂σαβ²∂σββ, :∂σαβ∂σββ², :∂σββ³
)
components(::typeof(dimension(UH.σ)), ::Unpolarized) = (:σ,)
components(::typeof(dimension(UH.∂ϵ_∂σ)), ::Unpolarized) = (:∂σ,)
components(::typeof(dimension(UH.∂²ϵ_∂ρ∂σ)), ::Unpolarized) = (:∂ρ∂σ,)
components(::typeof(dimension(UH.∂²ϵ_∂σ²)), ::Unpolarized) = (:∂σ²,)
components(::typeof(dimension(UH.∂³ϵ_∂ρ²∂σ)), ::Unpolarized) = (:∂ρ²∂σ,)
components(::typeof(dimension(UH.∂³ϵ_∂ρ∂σ²)), ::Unpolarized) = (:∂ρ∂σ²,)
components(::typeof(dimension(UH.∂³ϵ_∂σ³)), ::Unpolarized) = (:∂σ³,)

components(u::Unitful.FreeUnits, P::PolarizationCategory) = components(dimension(u), P)
components(u::DD.Scalars.All, P::PolarizationCategory) = components(dimension(u), P)
components(T::Type{<: DD.Scalars.All}, P::PolarizationCategory) =
    components(unitful_dimensions(T), P)
end
