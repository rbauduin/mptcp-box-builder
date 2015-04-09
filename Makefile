

default:
	./run.sh
livework/image.ova:
	./build-image.sh
mbdetect: livework/image.ova
	./pack-box.sh mbdetect.json
	
	
pack_mbdetect:
	./pack-box.sh mbdetect.json
