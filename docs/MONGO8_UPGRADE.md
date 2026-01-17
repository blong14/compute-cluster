# MongoDB Upgrade Path

## Upgrading to 8.0

Before upgrading to MongoDB 8.0, ensure that all Python applications using `pymongo` or `mongoengine` are compatible with the changes introduced in this version.

### Compatibility Changes: `None` vs. Missing Fields

A significant change in MongoDB 8.0 is how queries for `null` values are handled. In Python, `pymongo` and `mongoengine` translate `None` to BSON `null`.

**Before MongoDB 8.0:** A query for a field being `None` (i.e., `null`) would match documents where the field's value is `null` AND documents where the field does not exist at all.

**From MongoDB 8.0:** A query for a field being `None` will ONLY match documents where the field's value is explicitly `null`. It will NO LONGER match documents where the field is missing.

This change is relevant for our Python drivers.

For more details, see the official documentation: [Compatibility Changes in MongoDB 8.0](https://www.mongodb.com/docs/manual/release-notes/8.0-compatibility/#std-label-8.0-compatibility)

### Pre-upgrade checks for Python applications

1.  **Review application code:** Search for queries that might rely on the old behavior of matching missing fields when querying for `None`.
    -   **Pymongo:** Look for queries like `collection.find({"my_field": None})`.
    -   **Mongoengine:** Look for queries like `MyModel.objects(my_field=None)`.

    If your code expects these queries to return documents where `my_field` is missing, it will need to be updated. To match both `null` and missing fields in MongoDB 8.0 and later, you should use a query like:
    
    ```python
    # Pymongo
    collection.find({"$or": [{"my_field": None}, {"my_field": {"$exists": False}}]})

    # Mongoengine (using raw query)
    MyModel.objects(__raw__={"$or": [{"my_field": None}, {"my_field": {"$exists": False}}]})
    ```

2.  **Test applications:** Thoroughly test all applications against a MongoDB 8.0 staging environment to identify any issues related to this change.
