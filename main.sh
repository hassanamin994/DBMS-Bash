#!/bin/bash
##################################################
# Functions that creating tables
##################################################
function createTable {
	unset 'columnNames';
	unset 'columnType' ;
	echo "Please Enter Table's name ";
	read tableName ;
	if [ -f "$1/tableinfo/$tableName" ]
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
				break;;
			esac
		done
		touch $1/tableinfo/$tableName ;
		touch $1/tabledata/$tableName ;
		echo "Creating Table..."
		sleep 3;
		echo "primarykey:$primaryKey" > $1/tableinfo/$tableName ;

		for i in `seq 1 $numberOfColumns`
		do
			echo "${columnNames[i]}:${columnType[i]}" >> $1/tableinfo/$tableName ;
		done

		echo "Table Created Successfully ";
		echo "Table name is $tableName" ;
		echo "Table Content is " ;
		echo `cat $1/tableinfo/$tableName`;
		echo "Primary Key is $primaryKey" ;
	fi
}

##################################################
# Functions that handles inserting data
##################################################
function insertData {
	#echo "function insert data , parameter passed is $1 " ;
	let noOfColumns=`cat $2/tableinfo/$1 | wc -l`;
	primaryKey=`cat $2/tableinfo/$1 | cut -d: -f2 | cut -d$'\n' -f1` ;
	#echo "$primaryKey is primary key " ;
	for i in `seq 2 $noOfColumns`
	do
		columnsNames[$i]=`cat $2/tableinfo/$1 | cut -d: -f1 | cut -d$'\n' -f$i` ;
		columnsTypes[$i]=`cat $2/tableinfo/$1 | cut -d: -f2 | cut -d$'\n' -f$i` ;
	done
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
			#echo "this is the primary key  validation ";
			commandResult=`awk -v val="$primaryKeyValue" '{ if( $1 == val) print "true"  ; }' $2/tabledata/$1`;
			while [ $commandResult ]
			do
				echo "WARNING!! Primary Key Duplication, Please try another value...";
				read  inputs[$i] ;
				primaryKeyValue=${inputs[i]} ;
				commandResult=`awk -v val="$primaryKeyValue" '{ if( $1 == val) print "true"  ; }' $2/tabledata/$1`;
				echo $commandResult ;
			done
			#echo " Primary key accepted ";
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
	echo $primaryKeyValue $outputString >> $2/tabledata/$1 ;

	echo "Record was inserted Successfully as :"
	echo $outputString ;
	###############################################

}
function insert {
	echo "Select Table to insert into " ;
	noOfTables=`ls  $1/tableinfo | wc -w ` ;
	let backBtn=$noOfTables+1 ;
	# Getting the existing tables into an array
	for i in `seq 1 $noOfTables`
	do
		tables[$i]=`ls $1/tableinfo | tr " " "\n" | tr "\n" ":" | cut -f$i -d:` ;
		#echo "table element number $i is ${tables[i]}"
	done

	#echo "number of tables is $noOfTables" ;
	select choice in ${tables[@]} 'Back'
	do
	case $REPLY in
	[`seq 1 $noOfTables`] )
			#echo " you entered $choice ";
			insertData $choice $1;
		break;;
		$backBtn )
				return 0 ;
				;;
		* )
		echo "invalid input! Please try again "
	;;
	esac
	done

}

##################################################
# Functions that handles deleting data
##################################################
function deleteTable {
	echo "Select Table to Delete " ;
	noOfTables=`ls  $1/tableinfo | wc -w ` ;

	##############################################
	# Getting the existing tables into an array
	##############################################
	for i in `seq 1 $noOfTables`
	do
		tables[$i]=`ls $1/tableinfo | tr " " "\n" | tr "\n" ":" | cut -f$i -d:` ;
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
					rm $1/tableinfo/$choice $1/tabledata/$choice ;
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
	noOfTables=`ls  $1/tableinfo | wc -w ` ;

	##############################################
	# Getting the existing tables into an array
	##############################################
	for i in `seq 1 $noOfTables`
	do
		tables[$i]=`ls $1/tableinfo | tr " " "\n" | tr "\n" ":" | cut -f$i -d:` ;
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
			commandResult=`awk -v val="$PKey" '{ if( $1 == val) print "true"  ; }' $1/tabledata/$choice`;
			if [ $commandResult ]
			then
				echo "Record Found, Are you sure you want to delete the item ?" ;
				read ans;
				case $ans in
					[yY]* )
						echo "Deleting Record..." ;
						sleep 2;
						deleteCommand=`awk -v val="$PKey" '{ if( $1 != val) print $0 ; }' $1/tabledata/$choice >> $1/tabledata/${choice}.tmp | sleep 2 | mv $1/tabledata/${choice}.tmp $1/tabledata/${choice}`;
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
}
function deleteChoices {
	select del in 'Delete Table' 'Delete Record' 'Back'
	do
		case $del in
			'Delete Table' )
					clear;
					deleteTable $1 ;
					break;;
			'Delete Record' )
					clear;
					deleteRecord $1 ;

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

##################################################
# Functions that handles displaying information
##################################################
function displayFullTable {
	clear ;
	echo "Select Table to View From :" ;
	noOfTables=`ls  $1/tableinfo | wc -w ` ;
	let backBtn=noOfTables+1 ;
	# Getting the existing tables into an array
	for i in `seq 1 $noOfTables`
	do
		tables[$i]=`ls $1/tableinfo | tr " " "\n" | tr "\n" ":" | cut -f$i -d:` ;
	done
	select choice in ${tables[@]} 'Back'
	do
	case $REPLY in
	[`seq 1 $noOfTables`] )

			echo "Loading Table...";
			cat $1/tableinfo/$choice | cut -f1 -d: | tr '\n' ' ' | cat > tbl.tmp  ;
			echo " " >> tbl.tmp;
			cat $1/tabledata/$choice | column -t | cat >> tbl.tmp;

			sleep 1 ;
			clear ;
			cat tbl.tmp | column -t
			sleep 1 ;
			rm tbl.tmp ;
			sleep 1 ;
			break;;
			"$backBtn" )
				return 0 ;
				;;
		* )
		echo "invalid input! Please try again "
	;;
	esac
	done
}
function displayPartTable {
	clear;
	echo "Select Table to View From: " ;
	noOfTables=`ls  $1/tableinfo | wc -w ` ;
	let backBtn=$noOfTables+1;
	#################################################
	# Getting the existing tables into an array
	#################################################
	for i in `seq 1 $noOfTables`
	do
		tables[$i]=`ls $1/tableinfo | tr " " "\n" | tr "\n" ":" | cut -f$i -d:` ;
	done
	#################################################
	select choice in ${tables[@]} 'Back'
	do
	case $REPLY in
	[`seq 1 $noOfTables`] )
			clear;
			select typeOfView in 'View Part of Table' 'View Record by Primary Key ' 'Back'
			do
				case $typeOfView in
					'View Part of Table' )
						clear;
						#################################################
						# Viewing Head or Tail for a Table
						#################################################
						select part in 'View Head' 'View Tail' 'Back'
						do
							case $part in
								'View Head' )
									echo "Please Enter the number of lines you want to view ";
									read noOfLines;
									let noOfLines+=1;
									echo "Loading Table...";
									cat $1/tableinfo/$choice | cut -f1 -d: | tr '\n' ' ' | cat > tbl.tmp  ;
									echo " " >> tbl.tmp;
									cat $1/tabledata/$choice | column -t | cat >> tbl.tmp;
									sleep 3 ;
									clear ;
									head -$noOfLines tbl.tmp | column -t
									sleep 2 ;
									rm tbl.tmp ;
									echo " " ;
									break ;;
								'View Tail' )
									echo "Please Enter the number of lines you want to view ";
									read noOfLines;
									echo "Loading Info...";
									cat $1/tableinfo/$choice | cut -f1 -d: | tr '\n' ' ' | cat > tbl.tmp  ;
									echo " CAT PERFORMED ";
									echo " " >> tbl.tmp;
									sleep 1;
									tail -$noOfLines $1/tabledata/$choice >> tbl.tmp;
									sleep 3 ;
									clear ;

									cat tbl.tmp | column -t
									sleep 1 ;
									rm tbl.tmp ;
									echo " " ;

									break ;;
								'Back' )
									break;
									;;
									*)
									echo "Invalid input, Please try Again" ;
									;;
								esac
						done
					break;;
					#################################################

					#################################################
					# Viewing a record by its primary Key
					#################################################
					'View Record by Primary Key ' )
						clear;
						echo "Please enter Primary key for the record ";
						read primaryKeyValue ;
						commandResult=`awk -v val="$primaryKeyValue" '{ if( $1 == val) print "true"  ; }' $1/tabledata/$choice`;
						until [ $commandResult ]
						do
							echo "Primary Key Doesn't exist , Please try Again OR Type EXIT to Abort!";
							read primaryKeyValue
							if [ $primaryKeyValue == 'EXIT' -o $primaryKeyValue == 'exit' -o $primaryKeyValue == 'Exit' ]
							then
								break 2 ;
							else
								commandResult=`awk -v val="$primaryKeyValue" '{ if( $1 == val) print "true"  ; }' $1/tabledata/$choice`;
							fi
						done
						commandResult=`awk -v val="$primaryKeyValue" '{ if( $1 == val) print $0  ; }' $1/tabledata/$choice  `;
						echo "The Record Data is :"
						echo $commandResult ;
					break;;
					##################################################
					'Back' )
						clear;
						break;
					;;
					*)
					echo "Invalid input, Please try again" ;
					;;
				esac

			done
			break;;
		"$backBtn" )
			clear
			return 0 ;
			;;
		* )
			echo "invalid input! Please try again "
			;;
	esac
	done

}
function displayTables {
	clear;
	select choice in 'Display Full Table ' 'Display Part of Table' 'Back'
	do
		case $choice in
			'Display Full Table ' )
				displayFullTable $1 ;
				break;
			;;
			'Display Part of Table' )
				displayPartTable $1 ;
				break;
			;;
			'Back' )
				break ;
				;;
		esac

	done
}

##################################################
# Functions that handles manipulating databases
##################################################
function operationslist {

	while true
	do
		clear;
		select choice in 'Create Table' 'Insert New Record' 'Display' 'Delete' 'Back'
		do
			case $choice in
			'Create Table' )
				clear;
				createTable $1 ;
				echo "Press any key to continue..." ;
				read
				break;
			;;
			'Insert New Record' )
				clear;
				insert $1;
				echo "Press any key to continue..." ;
				read
				break;
				#echo "Press any key to continue..." ;
			;;
			'Display' )
				clear;
				displayTables $1 ;
				echo "Press any key to continue..." ;
				read
				break;
			;;
			'Delete' )
				clear;
				deleteChoices $1 ;
				echo "Press any key to continue..." ;
				read
				break;
			;;
			'Back' )
				return 0 ;
			;;
			* )
				echo "invalid input! Please try again "
			;;
			esac
		done
	done
}

##################################################
# Functions that handles databases
##################################################
function displayDatabases {
	clear;
	echo "Please Selected the Database to use :"
	#################################################
	# Getting the existing databases into an array
	#################################################
	unset 'databases' ;
	noOfDatabases=`ls -l | grep ^d | cut -d" " -f10 | wc -l ` ;
	let backBtn=$noOfDatabases+1 ;
	# Getting the existing tables into an array
	for i in `seq 1 $noOfDatabases`
	do
		databases[$i]=`ls -l | grep ^d | cut -d" " -f10 | grep .db$ | tr "\n" " " |  cut -f$i -d" " ` ;
	done
	#	echo ${databases[@]};
	select db in ${databases[@]} 'Back'
	do
		case $REPLY in
			[`seq 1 $noOfDatabases`] )
				clear;
				echo " Database $db Selected ";
				operationslist $db ;
				break ;
				;;
				"$backBtn" )
					clear;
					return 0 ;
					;;
				* )
					echo "Invalid input, Please try again!"
				;;
		esac
	done
}
function createDatabase {
	clear;
	echo "Please Enter Database name : ";
	read dbName ;
	if [ -d $dbName ]
	then
		echo "Database already exists ! " ;
	else
		clear ;
		echo "Creating Database..." ;
		mkdir $dbName.db ;
		sleep 2 ;
		echo "Initializing Schema..."
		mkdir $dbName.db/tableinfo $dbName.db/tabledata ;
		sleep 3 ;
		echo "Database Created Successfully ";
		return 0 ;
	fi
}
function deleteDatabase {
	#################################################
	# Getting the existing databases into an array
	#################################################
	clear ;
	echo "select a Database to delete " ;
	noOfDatabases=`ls -l | grep ^d | cut -d" " -f10 | wc -l ` ;
	let backBtn=$noOfDatabases+1 ;
	# Getting the existing tables into an array
	for i in `seq 1 $noOfDatabases`
	do
		databases[$i]=`ls -l | grep ^d | cut -d" " -f10 | grep .db$ | tr "\n" " " |  cut -f$i -d" " ` ;
	done
	#	echo ${databases[@]};
	select db in ${databases[@]} 'Back'
	do
		case $REPLY in
			[`seq 1 $noOfDatabases`] )
				clear;
				echo " Database $db Selected ";
				echo "Are you sure you want to delete $db ?!! " ;
				read YorN ;
				case $YorN in
					[yY]* )
						echo "Deleting Database $db ... ";
						rm -R $db ;
						sleep 2;
						echo "Database Removed Successfully ";
						break ;
						;;
						[nN]* )
							echo "Aborting..."
							return 0 ;
						break;
						;;
						* )
							echo "Invalid Input, Aborting...";
						break;
						;;
					esac
				# if [ $YorN = [yY]* ]
				# then
				# 	echo "Deleting Database $db ... ";
				# 	rm -R $db ;
				# 	sleep 2;
				# 	echo "Database Removed Successfully ";
				# elif [ $YorN = [nN]* ]
				# then
				# 	echo "Aborting..."
				# 	sleep 2 ;
				# 	return 0 ;
				# else
				# 	echo "Invalid input,Aborting !!!" ;
				# fi
				break ;
				;;
				"$backBtn" )
					clear;
					return 0 ;
					;;
				* )
					echo "Invalid input, Please try again!"
				;;
		esac
	done
}
##################################################

	clear;
	select choice in 'Use Database' 'Create Database' 'Delete Database' 'Exit'
	do
	clear;
		case $choice in
			'Use Database' )
				clear;
				displayDatabases ;
				echo "Press any key to contine.."

				;;
			'Create Database' )
				clear;
				createDatabase ;
				echo "Press any key to contine.."

				;;
			'Delete Database' )
				clear;
				deleteDatabase ;
				echo "Press any key to contine.."

				;;
			'Exit' )
				echo "Bye!";
				exit 0 ;
				;;
				* )
					echo "Invalid input, Please try again!" ;
					;;
			esac
	done
