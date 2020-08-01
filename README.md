#	Download COVID-19 data and generate graphs
		Require 
				gnuplot		for drawing graphs
				wget 		get data from web page
				git			get data from Johns Hopkins CCSE data
				ps2ascii	combert pdf to text

	cov19.pl [ccse who jag jagtotal] 
		-NC 		New cases
		-ND 		New deathes
		-NR			New recovers
		-CC			Cumelative cases toll
		-CD			Cumelative deathes toll
		-CR			Cumelative recovers

		--POP		count/population (M)
		--FT		Finatial Times like graph
		--ERN		Effective reproduction number

		-dl			Download data

		-full		do all all data srouces and functions 
		-FULL		-full with download

	cov19.pl -> ccse	 ccse.pm 	John Hopkins univ. ccse
			 -> who		 who.pm		WHO situation report
			 -> jag		 jag.pm		J.A.G Japan data of Japan
			 -> jagtotal jagtotal.pm	Total of all prefectures on J.A.A Japan 
			 -> tko		 tko.pm		Japan data from Tokyo Open Data
			 -> ku		 tkoku.pm	Tokyo City, Town data from Tokoto(Shinjyukuku)
			 -> usa		 usa.pm		US States data
			 -> usast	 usast.pm	US city, town data
			 -> tkpos	 tkpos.pl	Tokyo Positive Rate, server etc
			 -> tkage	 tkoage.pm	Tokyo age based data

	AGGR_MODE
		DAY				Daily count of the source data
		POP				Daily count / population (M)

	SUB_MODE
		COUNT			Simply count
		FT(ft.pm)		Finatial Times like 
		ERN(ern.pm)		Effective reproduction number

	MODE
		NC				New Cases
		ND				New Deaths
		NR				New Recoverd
		CC				Ccumulative Cases
		CD				Ccumulative Deatheas
		CR				Ccumulative Deatheas



 our $PARAMS = {			# MODULE PARETER		$mep
    comment => "**** J.A.G JAPAN PARAMS ****",
    src => "JAG JAPAN",
	src_url => $src_url,
    prefix => "jag_",
    src_file => {
		NC => $transaction,
		ND => "",
    },

    new => \&new,
    aggregate => \&aggregate,
    download => \&download,
    copy => \&copy,
	
	COUNT => {			# FUNCTION PARAMETER		$funcp
		EXEC => "",
		graphp => [		# GPL PARAMETER				$gplp
			{ext => "#KIND# Japan 01-05 (#LD#) #SRC#", start_day => "02/15",  lank =>[0, 4] , exclusion => $EXCLUSION, target => "", label_skip => 2, graph => "lines"},


		ext			Title of the graph 
						#KIND#	Mode-Submode-Aggrmode
						#LD#	Last Date of the graph

		start_day	First day of the graph 
						number (0, 11)		Abslute number of the data
						number (-7, -30)	Relative date from today
						"07/30"				Actual date
		end_day		Last date of the graph
		lank		Graph Items (like Top 10, 11-15)	[from, to]	
		exclusion	Exclusion graph items (like, US, Others)
		target		Taraget items for the graph (Like 東京, US, Sweden)
		add_target	Additional target(ex, [0,5] + Japan)
		label_skip	labels skip (Date)
		graph		lines or boxes
		avr_date	Rolling Average term 
		average_date	Rolling Average for FT	(may fix this)
		ymax		ymax of the graph
		ymin		ymin of the graph
		thresh		Thresh unnormally high data

		logscale	logscale 	"y" or "x" ,,,, actually only "y"
		term_ysize	Graph Ysize
		nosort		Do not sort by the value(ex. tkage)
		ruiseki		ruiseki data (ex. tkage )
		ft			FinatialTimes style graph
		series		Use number for X instead of Dates



our %SORT_BALANCE = (
        NC => [0.7,  0.1],      # 0.5 0.05  0, 0
        ND => [0.7,  0.1],
        NR => [0.7,  0.1],
        CC => [0.99, 0.1],
        CD => [0.99, 0.1],
        CR => [0.99, 0.1],

        ERN => [0.99, 0.1],
        FT => [0.5, 0.3],
        KV => [0.99, 0.1],
);
