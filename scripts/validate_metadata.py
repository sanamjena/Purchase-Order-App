#!/usr/bin/env python3
"""Local metadata sanity checks for the Purchase Order app."""

from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
FORCE_APP = ROOT / "force-app"


def parse_all_xml() -> list[Path]:
    failures: list[Path] = []
    for xml_file in FORCE_APP.rglob("*.xml"):
        try:
            ET.parse(xml_file)
        except ET.ParseError:
            failures.append(xml_file)
    return failures


def assert_exists(path: Path, label: str) -> list[str]:
    if not path.exists():
        return [f"Missing required {label}: {path.relative_to(ROOT)}"]
    return []


def run() -> int:
    errors: list[str] = []

    parse_failures = parse_all_xml()
    errors.extend([f"Invalid XML: {p.relative_to(ROOT)}" for p in parse_failures])

    errors.extend(assert_exists(FORCE_APP / "main/default/objects/Purchase_Order__c/Purchase_Order__c.object-meta.xml", "purchase order object"))
    errors.extend(assert_exists(FORCE_APP / "main/default/objects/Purchase_Order_Line__c/Purchase_Order_Line__c.object-meta.xml", "purchase order line object"))
    errors.extend(assert_exists(FORCE_APP / "main/default/classes/PurchaseOrderService.cls", "service class"))
    errors.extend(assert_exists(FORCE_APP / "main/default/lwc/purchaseOrderManager/purchaseOrderManager.js", "manager LWC"))

    if errors:
        print("Metadata validation failed:")
        for error in errors:
            print(f" - {error}")
        return 1

    print("Metadata validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(run())
