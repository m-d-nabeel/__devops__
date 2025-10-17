import json
import logging
import os
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)


# Errors that should not be retried
class PermanentError(Exception):
    pass


# Errors that may succeed if retried
class TransientError(Exception):
    pass


def _load_max_attempts(default: int = 2) -> int:
    raw_value = os.getenv("MAX_RETRY_ATTEMPTS")
    if raw_value is None:
        return default
    try:
        return int(raw_value)
    except ValueError:
        return default


MAX_RETRY_ATTEMPTS = _load_max_attempts()


def process(body_dict):
    """Simulate downstream behavior so tests can exercise retry paths."""
    time.sleep(3)  # Simulate processing time testing
    simulate = body_dict.get("simulate", "success")

    if simulate == "success":
        return
    if simulate == "transient":
        raise TransientError(body_dict.get("reason", "simulated transient failure"))
    if simulate == "permanent":
        raise PermanentError(body_dict.get("reason", "simulated permanent failure"))
    if simulate == "unknown":
        raise RuntimeError(body_dict.get("reason", "simulated unexpected error"))

    return


def lambda_handler(event, context):
    failures = []
    for record in event["Records"]:
        msg_id = record["messageId"]
        receive_count = int(record["attributes"]["ApproximateReceiveCount"])
        try:
            body = json.loads(record["body"])
        except json.JSONDecodeError:
            logger.warning(
                "terminal_drop invalid_json messageId=%s count=%d",
                msg_id,
                receive_count,
            )
            continue

        try:
            process(body)
            logger.info("processed messageId=%s count=%d", msg_id, receive_count)
        except PermanentError as e:
            logger.warning(
                "terminal_drop permanent messageId=%s count=%d reason=%s",
                msg_id,
                receive_count,
                e,
            )
        except TransientError as e:
            if receive_count <= MAX_RETRY_ATTEMPTS:
                failures.append({"itemIdentifier": msg_id})
                logger.info(
                    "retrying transient messageId=%s count=%d reason=%s max=%d",
                    msg_id,
                    receive_count,
                    e,
                    MAX_RETRY_ATTEMPTS,
                )
            else:
                logger.warning(
                    "terminal_drop transient_threshold_exceeded messageId=%s count=%d reason=%s",
                    msg_id,
                    receive_count,
                    e,
                )
        except Exception as e:
            if receive_count <= MAX_RETRY_ATTEMPTS:
                failures.append({"itemIdentifier": msg_id})
                logger.exception(
                    "retrying unknown_error messageId=%s count=%d max=%d",
                    msg_id,
                    receive_count,
                    MAX_RETRY_ATTEMPTS,
                )
            else:
                logger.exception(
                    "terminal_drop unknown_after_threshold messageId=%s count=%d",
                    msg_id,
                    receive_count,
                )

    return {"batchItemFailures": failures}
