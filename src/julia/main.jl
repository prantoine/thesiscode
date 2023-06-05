module ThesisPlots

using CSV, Plots, DataFrames, StatsPlots, PlotlyJS, Statistics


"""
    Reads the CSV file two directories up and in the "merged_data" directory.
"""
function read_csv(df_name::String)

    return CSV.read(joinpath(dirname(dirname(dirname(pwd()))), "merged_data", df_name), DataFrame)

end


"""
    Price premium graph for the main regions.
"""
function plot_op_prices(df_name)

    raw_df = read_csv(df_name)
    sort!(raw_df, :event_time)
    transform!(groupby(raw_df, [:event_time, :region_agg]), [:dry_op_trader_2015cpi, :dry_op_farmgate_2015cpi] .=> mean .=> Symbol.("avg_", [:dry_op_trader_2015cpi, :dry_op_farmgate_2015cpi]))
    raw_df[!, :price_diff] .= raw_df[:, :avg_dry_op_trader_2015cpi] .- raw_df[:, :avg_dry_op_farmgate_2015cpi]
    plot_prices = @df raw_df Plots.plot(:event_time, :price_diff, group={Region=:region_agg})
    ylabel!("2015\$ per kg")
    display(plot_prices)
    #Plots.savefig(plot_prices, "fig_price_diff_region.png")

end


"""
    Graph displaying raw number of conflict events over the years.
"""
function plot_all_conflicts(df_name)

    raw_df = read_csv(df_name)
    transform!(groupby(raw_df, [:year, :event_type]), nrow => :obs_conflicts)
    sort!(raw_df, [:year, :event_type])
    df_to_stack = transform(groupby(raw_df, [:year, :event_type]), eachindex => :index)
    filter!(:index => ==(1), df_to_stack)
    select!(df_to_stack, [:year, :event_type, :obs_conflicts])
    println(df_to_stack)
    p = PlotlyJS.plot(df_to_stack, kind="bar", x=:year, y=:obs_conflicts, color=:event_type, Layout(legend=(attr(x=5, y=0.5,)),barmode="stack", legend_title_text="Event type", xaxis_title="Year", yaxis_title="Number of conflict events"))
    display(p)

end


"""
    Main graph: plot different types of conflicts (price vs no price).
"""
function plot_price_vs_no_price(df_name)

    raw_df = read_csv(df_name)
    println(names(raw_df))

    plot_battles = @df raw_df Plots.plot(:event_YM, [:mean_battles_no_price, :mean_battles_price], label=["Poppy-free provinces" "Poppy producing provinces"], legend=:bottomleft, ls=[:dashdot :dot], lw=1.3, color=[:blue :red], rightmargin=1Plots.cm, leftmargin=1Plots.cm, ylabel="Average monthly battle events")
    subp = twinx()
    @df raw_df Plots.plot!(subp, :event_YM, :mean_trader_price, label="Average opium trader prices (right axis)", legend=:topright, line=:solid, color=:black, lw=2, ylabel="2015 \$")
    
    plot_remoteviolence = @df raw_df Plots.plot(:event_YM, [:mean_remoteviolence_no_price, :mean_remoteviolence_price], label=["Poppy-free provinces" "Poppy producing provinces"], legend=:bottomleft, ls=[:dashdot :dot], lw=1.3, color=[:blue :red], ylabel="Average monthly remote violence events")
    subp2 = twinx()
    @df raw_df Plots.plot!(subp2, :event_YM, :mean_trader_price, label="Average opium trader prices (right axis)", legend=:topright, line=:solid, color=:black, lw=2, ylabel="2015 \$")

    plot_talibanconflicts = @df raw_df Plots.plot(:event_YM, [:mean_conflicts_taliban_no_price, :mean_conflicts_taliban_price], label=["Poppy-free provinces" "Poppy producing provinces"],legend=:bottomleft, ls=[:dashdot :dot], lw=1.3, color=[:blue :red], ylabel="Average monthly taliban conflict events")
    subp3 = twinx()
    @df raw_df Plots.plot!(subp3, :event_YM, :mean_trader_price, label="Average opium trader prices (right axis)", legend=:topright, line=:solid, color=:black, lw=2, ylabel="2015 \$")

    plot_fatalities = @df raw_df Plots.plot(:event_YM, [:mean_fatalities_month_no_price, :mean_fatalities_month_price], label=["Poppy-free provinces" "Poppy producing provinces"],legend=:bottomleft, ls=[:dashdot :dot], lw=1.3, color=[:blue :red], ylabel="Average monthly fatalities")
    subp4 = twinx()
    @df raw_df Plots.plot!(subp4, :event_YM, :mean_trader_price, label="Average opium trader prices (right axis)", legend=:topright, line=:solid, color=:black, lw=2, ylabel="2015 \$")

    joint_plots = Plots.plot(plot_battles, plot_remoteviolence, plot_talibanconflicts, plot_fatalities,layout=4, size=(1400,1000), rightmargin=1Plots.cm, leftmargin=1Plots.cm)

    #Mean violence and opium trader prices in Afghan provinces
    subp5 = twinx()
    @df raw_df Plots.plot!(subp5, :event_YM, :mean_price_premium, label="Average price premium for the trader (right axis)", legend=:topright, line=:solid, color=:black, lw=2, ylabel="2015 \$")
    display(joint_plots)

end


"""
    Displays heroin prices for the different regions.
"""
function plot_h_prices(df_name::String)

    raw_df = read_csv(df_name)
    println(names(raw_df))

    sort!(raw_df, [:event_YM, :region_agg])
    plot_heroin = @df raw_df Plots.plot(:event_YM, :h_prices_2015cpi, group={Region=:region_agg})
    ylabel!("Heroin prices, 2015\$")
    display(plot_heroin)
    #Plots.savefig(plot_heroin, "heroin_prices.png")

end

# uncomment to display each graph below.

plot_op_prices("main_panel.csv")
#plot_all_conflicts("acled_data_pre_merge.csv")
#plot_price_vs_no_price("pricevsnoprice_conflicts.csv")
#plot_h_prices("main_panel.csv")


end