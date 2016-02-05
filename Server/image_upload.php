<?php
	require 'vendor/autoload.php';	
	
	date_default_timezone_set('Asia/Tokyo');

	use Parse\ParseClient;
	use Parse\ParseObject;
	use Parse\ParseQuery;

	define('PARSE_APPLICATION_ID', '<YOUR_PARSE_APPLICATION_ID>' );
	define('PARSE_REST_API_KEY', '<YOUR_PARSE_REST_API_KEY>' );
	define('PARSE_MASTER_KEY', '<YOUR_PARSE_MASTER_KEY>' );
	
	define('IDP_PHOTO_IMAGE_CLASS_NAME', 'PhotoImage' );
	define('IDP_UPLOAD_TICKET_CLASS_NAME', 'UploadTicket' );
	define('IDF_STORE_SUB_FOLDER_CLASS_NAME', 'StoreSubFolder' );
	
	if( PARSE_APPLICATION_ID == '<YOUR_PARSE_APPLICATION_ID>' || PARSE_REST_API_KEY == '<YOUR_PARSE_REST_API_KEY>' || PARSE_MASTER_KEY == '<YOUR_PARSE_MASTER_KEY>'){
		
        $response = new StdClass;
		if( PARSE_APPLICATION_ID == '<YOUR_PARSE_APPLICATION_ID>' ){
	        $response->errorDescription = "application ID empty.";
		}else if(PARSE_REST_API_KEY == '<YOUR_PARSE_REST_API_KEY>'){
	        $response->errorDescription = "REST API key empty.";
		}else if(PARSE_MASTER_KEY == '<YOUR_PARSE_MASTER_KEY>'){
	        $response->errorDescription = "master key empty.";
		}
        header('Content-type: application/json');
        echo stripslashes(json_encode($response));
	}else{
		ParseClient::initialize(PARSE_APPLICATION_ID, PARSE_REST_API_KEY, PARSE_MASTER_KEY);

		$subFolderPath = 'images';

		// SubFolder検出
		$queryStoreSubFolder = new ParseQuery(IDF_STORE_SUB_FOLDER_CLASS_NAME);

		$s_folderSelector =  htmlspecialchars($_POST['selector'], ENT_QUOTES);
		if( strlen($s_folderSelector) > 0  ){
			$queryStoreSubFolder->equalTo('selector',$s_folderSelector);
		}else{
			$queryStoreSubFolder->doesNotExist('selector');
		}
		
		// サブフォルダを検索
		$resultsStoreSubFolder = $queryStoreSubFolder->find();

		// ランダムで取得
		if( count($resultsStoreSubFolder) ){
			$subfolderObject = $resultsStoreSubFolder[array_rand($resultsStoreSubFolder,1)];
			
			$subFolderPath = $subfolderObject->get('path');

			$dir = getcwd() . '/' . $subFolderPath;
			 if (!is_dir($dir)) {
                if (!mkdir($dir)) {
                    throw new RuntimeException('Failed to create directory: ' . $dir);
                }
                chmod($dir, 0777);
            }
		}
	
		// チケット名を取得
		$s_ticketName =  htmlspecialchars($_POST['name'], ENT_QUOTES);
	
		$query = new ParseQuery(IDP_UPLOAD_TICKET_CLASS_NAME);
		$query->equalTo('name', $s_ticketName );
		$results = $query->find();
	
		if( count($results) ){
			$ticketObject = $results[0];
	
			if (!isset($_FILES["file"]["error"]) ||  !is_int($_FILES["file"]["error"])) {
		        throw new RuntimeException('parameter failure.');
		    }
			
			switch ($_FILES["file"]["error"]) {
		        case UPLOAD_ERR_OK:
		            break;
		        case UPLOAD_ERR_NO_FILE:
		            throw new RuntimeException('no file.');
		        case UPLOAD_ERR_INI_SIZE:
		        case UPLOAD_ERR_FORM_SIZE:
		            throw new RuntimeException('file size too large.');
		        default:
		            throw new RuntimeException('unresolved error');
		    }
			
		    // Allowed extentions.
		    $allowedExts = array('gif','jpeg','jpg','png','pdf');
		    $allowedMINEs = array('image/gif','image/jpeg','image/x-png','image/png','application/pdf');
		    
		    // Get filename.
		    $temp = explode(".", $_FILES["file"]["name"]);
		
		    // Get extension.
		    $extension = strtolower(end($temp));
		    
		    // An image check is being done in the editor but it is best to
		    // check that again on the server side.
		    // Do not use $_FILES["file"]["type"] as it can be easily forged.
		    $finfo = finfo_open(FILEINFO_MIME_TYPE);
		    $mime = finfo_file($finfo, $_FILES["file"]["tmp_name"]);
		
		    if ((in_array($mime, $allowedMINEs) && in_array($extension, $allowedExts))) {
		        // Generate new random name.
		        $name = sha1(microtime()) . "." . $extension;
		
		        // Save file in the uploads folder.
		        move_uploaded_file($_FILES["file"]["tmp_name"], getcwd() . '/' . $subFolderPath . '/' . $name);
		
	    	    $photoImage = new ParseObject(IDP_PHOTO_IMAGE_CLASS_NAME);
			    $photoImage->set('path', $subFolderPath . '/' . $name);
		    
				try {
				  $photoImage->save();
				  
			        // Generate response.
			        $response = new StdClass;
			        $response->objectID = $photoImage->getObjectId();

		            header('Content-type: application/json');
			        echo stripslashes(json_encode($response));
				} catch (ParseException $ex) {  
			        $response = new StdClass;
			        $response->errorDescription = "save failue";
			        header('Content-type: application/json');
			        echo stripslashes(json_encode($response));
				}	    
		    }
		    
		    // Ticketを削除
		    $ticketObject->destroy();
		    
		}else{
	        $response = new StdClass;
	        $response->errorDescription = "upload failue";
	        header('Content-type: application/json');
	        echo stripslashes(json_encode($response));
		}
		
	}

?>