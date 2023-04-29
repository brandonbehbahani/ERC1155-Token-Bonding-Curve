import "./Roles.sol";

contract GasSetterRole {
    using Roles for Roles.Role;

    event GasSetterAdded(address indexed account);
    event GasSetterRemoved(address indexed account);

    Roles.Role private _gasSetters;

    constructor () internal {
        _addGasSetter(msg.sender);
    }

    modifier onlyGasSetter() {
        require(isGasSetter(msg.sender), "GasSetterRole: caller does not have the GasSetter role");
        _;
    }

    function isGasSetter(address account) public view returns (bool) {
        return _gasSetters.has(account);
    }

    function addGasSetter(address account) public onlyGasSetter {
        _addGasSetter(account);
    }

    function renounceGasSetter() public {
        _removeGasSetter(msg.sender);
    }

    function _addGasSetter(address account) internal {
        _gasSetters.add(account);
        emit GasSetterAdded(account);
    }

    function _removeGasSetter(address account) internal {
        _gasSetters.remove(account);
        emit GasSetterRemoved(account);
    }
}