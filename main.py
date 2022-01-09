import asyncio
import logging
import time


from cmd.run import main


logging.basicConfig(
    level=logging.DEBUG,
    format=('[%(asctime)s] %(levelname)-8s %(name)-12s %(message)s'),
    handlers=[logging.StreamHandler()],)

logger = logging.getLogger(__name__)


if __name__ == '__main__':
    start_time = time.time()
    logger.info('running async version...')
    asyncio.run(main())
    logger.info('--- %s seconds ---', time.time() - start_time)

