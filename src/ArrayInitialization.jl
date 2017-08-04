module ArrayInitialization

using Unitful
using AxisArrays
using ..UnitfulHartree
using ..Traits: components, Polarized, Unpolarized, PolarizationCategory
using ..Dispatch

macro lintpragma(s) end

const DD = Dispatch.Dimensions

""" Creates the tuple of axes for a spin-polarized quantity """
@generated polarized_axis(comps::Tuple, defaults::Tuple, ax::Tuple) = begin
    if length(ax.parameters) == length(defaults.parameters)
        :(defaults)
    elseif length(ax.parameters) == length(defaults.parameters) - 1
        :(ax..., Axis{:spin}(comps))
    else
        :(Base.front(defaults)..., Axis{:spin}(comps))
    end
end

""" Creates an unpolarized array for the given DFT quantity """
Base.zeros(T::Type{<:DD.Scalars.All}, ::Type{Polarized},  dims::Tuple, ax::Tuple) = begin
    length(ax) > (length(dims) + 1) && throw(ArgumentError("Too many axes"))
    comps = components(T, Polarized)
    data = zeros(T, (dims..., length(comps)))
    defaults = AxisArrays.default_axes(data, ax)
    AxisArray(data, polarized_axis(comps, defaults, ax))
end
Base.zeros(T::Type{<:DD.Scalars.All}, ::Type{Polarized}, dims::Tuple) = begin
    comps = components(T, Polarized)
    data = zeros(T, (dims..., length(comps)))
    defaults = AxisArrays.default_axes(data)
    AxisArray(data, Base.front(defaults)..., Axis{:spin}(comps))
end
""" Creates an unpolarized array for the given DFT quantity """
Base.zeros(T::Type{<:DD.Scalars.All}, ::Type{Unpolarized}, dims::Tuple, ax::Tuple) =
    AxisArray(zeros(T, dims), ax...)
Base.zeros(T::Type{<:DD.Scalars.All}, ::Type{Unpolarized}, dims::Tuple) =
    AxisArray(zeros(T, dims))
    
    
@lintpragma("Ignore unused args")
"""
Creates an array for the given DFT quantity

The spin components, if any, are added as the last dimension.
Note should `dims` does not include the spin components.
"""
Base.zeros(T::Type{<:DD.Scalars.All}, P::Type{<: PolarizationCategory},
           args::Vararg{<:Union{Integer, Axis}}) = begin
    @lintpragma("Ignore use of undeclared variable x")
    zeros(T, P, ((x for x in args if typeof(x) <: Integer)...),
            ((x for x in args if typeof(x) <: Axis)...))
end
Base.zeros(T::Type{<:DD.Scalars.All}, polarized::Bool,
           args::Vararg{<:Union{Integer, Axis}}) =
    zeros(T, polarized ? Polarized: Unpolarized, args...)
end