clean:
	rm -rf website.tar
build-docker:
	docker build -t website .
package:
	docker run -v `pwd`:/data -it website /data/scripts/build-website.sh
