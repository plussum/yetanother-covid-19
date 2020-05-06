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


