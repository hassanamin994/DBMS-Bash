#!/bin/bash
function createTable {
	echo "Please Enter Table's name ";
	read tableName ;
	if [ -f "tableinfo/$tableName" ]
	then
		echo "table already exists ! " ;
	else
		echo "Please Enter the number of Columns ";
		read numberOfColumns ;
		let numberOfColumns=$numberOfColumns ;

		for i in $(seq 1 $numberOfColumns)
		do
			echo "Enter Name for Column number $i " ;
			read columnNames[i] ;
			echo "Choose Datatype for Column ${columnNames[i]}"

			select choice in "Integer" "String"
			do
				case $choice in
					"Integer" )
						columnType[i]="integer" ;
					  break;;
					"String" )
						columnType[i]="string" ;
					  break;;
						* )
							echo "Invalid input, Please try Again!" ;
							;;
					esac
			done

		done

		echo "Which column to be set as Primary Key ?"
		select choice in ${columnNames[@]}
		do
			case $choice in
				*)
				primaryKey=${columnNames[$REPLY]}
				echo "reply variable is $REPLY" ;
				break;;
			esac
		done
		touch tableinfo/$tableName ;
		touch tabledata/$tableName ;
		echo "primarykey:$primaryKey" > tableinfo/$tableName ;

		for i in `seq 1 $numberOfColumns`
		do
			echo "${columnNames[i]}:${columnType[i]}" >> tableinfo/$tableName ;
		done

		echo "Table Created Successfully ";
		echo "Table name is $tableName" ;
		echo "Table Content is " ;
		echo `cat tableinfo/$tableName`;
		echo "Primary Key is $primaryKey" ;
	fi
}
function insertData {
	#echo "function insert data , parameter passed is $1 " ;
	let noOfColumns=`cat tableinfo/$1 | wc -l`;
	primaryKey=`cat tableinfo/$1 | cut -d: -f2 | cut -d$'\n' -f1` ;
	echo "$primaryKey is primary key " ;
	for i in `seq 2 $noOfColumns`
	do
		columnsNames[$i]=`cat tableinfo/$1 | cut -d: -f1 | cut -d$'\n' -f$i` ;
		columnsTypes[$i]=`cat tableinfo/$1 | cut -d: -f2 | cut -d$'\n' -f$i` ;
	done
	echo ${columnsNames[@]};
	for i in `seq 2 $noOfColumns`
	do
		##############################################
		# Warning user he's entering the Primary Key
		##############################################
		if [ ${columnsNames[i]} == $primaryKey ]
		then

			echo "Warning! This is the primary Key " ;
			echo "Please ensure not to repeat an already existing value" ;
			echo "Please Enter value for column ${columnsNames[i]} with type ${columnsTypes[i]}"
			read  inputs[$i] ;
			primaryKeyValue=${inputs[i]} ;
		else
		###############################################
		echo "Please Enter value for column ${columnsNames[i]} with type ${columnsTypes[i]}"
		read  inputs[$i] ;
		fi
		###############################################
		# Primary key Validation
		##############################################
		if [ ${columnsNames[i]} == $primaryKey ]
		then
			echo "this is the primary key  validation ";
			commandResult=`awk -v val="$primaryKeyValue" '{ if( $1 == val) print "true"  ; }' tabledata/$1`;
			while [ $commandResult ]
			do
				echo "WARNING!! Primary Key Duplication, Please try another value...";
				read  inputs[$i] ;
				primaryKeyValue=${inputs[i]} ;
				commandResult=`awk -v val="$primaryKeyValue" '{ if( $1 == val) print "true"  ; }' tabledata/$1`;
				echo $commandResult ;
			done
			echo " Primary key accepted ";
		fi
		# awk 'BEGIN{ keyExists=false }{ if( $1 == $primaryKeyValue) keyExists=true ;} END{ echo $keyExists} ' tabledata/hassan
		###############################################

		###############################################
		# Data Type Validation
		##############################################
		if [ "${columnsTypes[i]}" == "integer"  ] 2>/dev/null
		then
			until [ "${inputs[i]}" -eq "${inputs[i]}" ]   2>/dev/null
 		 	do
 				echo "Invalid datatype , please enter an integer" ;
				read inputs[$i] ;
 		 	done
		fi
		################################################

	done
	###############################################
	# Writing into Table File
	##############################################
	outputString=${inputs[@]} ;
	echo $primaryKeyValue $outputString >> tabledata/$1 ;

	echo "Record was inserted Successfully as :"
	echo $outputString ;
	###############################################

}
function insert {
	echo "Select Table to insert into " ;
	noOfTables=`ls  tableinfo | wc -w ` ;
	# Getting the existing tables into an array
	for i in `seq 1 $noOfTables`
	do
		tables[$i]=`ls tableinfo | tr " " "\n" | tr "\n" ":" | cut -f$i -d:` ;
		#echo "table element number $i is ${tables[i]}"
	done

	echo "number of tables is $noOfTables" ;
	select choice in ${tables[@]} 'Back'
	do
	case $REPLY in
	[`seq 1 $noOfTables`] )
			echo " you entered $choice ";
			insertData $choice ;
			echo "Press Any Key to continue.." ;
		break;;
		'Back' )
				return 0 ;
				;;
		* )
		echo "invalid input! Please try again "
	;;
	esac
	done

}
function deleteTable {
	echo "Select Table to Delete " ;
	noOfTables=`ls  tableinfo | wc -w ` ;

	##############################################
	# Getting the existing tables into an array
	##############################################
	for i in `seq 1 $noOfTables`
	do
		tables[$i]=`ls tableinfo | tr " " "\n" | tr "\n" ":" | cut -f$i -d:` ;
	done
	##############################################

	##############################################
	# Performing Deletion for the Table
	##############################################
	select choice in ${tables[@]} 'Back'
	do
	case $REPLY in
	[`seq 1 $noOfTables`] )
			echo " Are you Sure you want to Delete Table : $choice ? y/n ";
			read YorN ;
			case $YorN in
				[yY]* )
					rm tableinfo/$choice tabledata/$choice ;
					echo "Table Deleted Successfully ";
					break;;
				* )
					break ;;
			esac
		break;;
		'Back' )
				return 0 ;
				;;
		* )
		echo "invalid input! Please try again "
	;;
	esac
	done
	##############################################
}
function deleteRecord {
	echo "Select Table to Delete From " ;
	noOfTables=`ls  tableinfo | wc -w ` ;

	##############################################
	# Getting the existing tables into an array
	##############################################
	for i in `seq 1 $noOfTables`
	do
		tables[$i]=`ls tableinfo | tr " " "\n" | tr "\n" ":" | cut -f$i -d:` ;
	done
	##############################################

	##############################################
	# Performing Deletion for a Record
	##############################################
	select choice in ${tables[@]} 'Back'
	do
	case $REPLY in
	[`seq 1 $noOfTables`] )
			# $choice
			while true
			do

			echo " Please Enter The Primary Key for the Record ";
			read PKey ;
			commandResult=`awk -v val="$PKey" '{ if( $1 == val) print "true"  ; }' tabledata/$choice`;
			if [ $commandResult ]
			then
				echo "Record Found, Are you sure you want to delete the item ?" ;
				read ans;
				case $ans in
					[yY]* )
						echo "Deleting Record..." ;
						sleep 2;
						deleteCommand=`awk -v val="$PKey" '{ if( $1 != val) print $0 ; }' tabledata/$choice >> tabledata/${choice}.tmp | sleep 2 | mv tabledata/${choice}.tmp tabledata/${choice}`;
						break ;
					;;
					[nN]* )
						break ;
					;;
					* )
						echo "Unknown input, Aborting!!!"
						break ;
					;;
					#break ;
				esac
			else
				echo " Primary Key Doesn't Exist, Please try again!!!"
			fi
			done
			case $YorN in
				[yY]* )

					break;;
				* )
					clear ;
					return 0 ;;
			esac
		break;;
		'Back' )
				return 0 ;
				;;
		* )
		echo "invalid input! Please try again "
	;;
	esac
	done
	##############################################
	echo "Delete Record Function " ;
}
function deleteChoices {
	select del in 'Delete Table' 'Delete Record' 'Back'
	do
		case $del in
			'Delete Table' )
					clear;
					deleteTable ;
					break;;
			'Delete Record' )
					clear;
					deleteRecord ;

					break;;
			'Back' )
					return 0 ;
					;;
				* )
					echo "Invalid input! Please Try Again..."
					;;
		esac
	done
}
select choice in 'Create Table' 'Insert New Record' 'Display' 'Delete' 'Exit'
do

case $choice in
'Create Table' )
	clear;
	createTable ;
;;
'Insert New Record' )
	clear;
	insert ;
	echo "Press any key to continue..." ;
;;
'Display' )
	clear;
	echo "Displaying a table or record "
	echo "Press any key to continue..." ;
;;
'Delete' )
	clear;
	deleteChoices ;
	echo "Record Deleted Successfully ";
	echo "Press any key to continue..." ;
;;
'Exit' )
	echo "Bye!"
	exit 0 ;
;;
* )
	echo "invalid input! Please try again "
;;
esac
done
