%global pypi_name jc
%global desc JSON CLI output utility. JC is used to JSONify the output of many linux\
CLI tools and file types for easier parsing in scripts.

Name:           %{pypi_name}
Version:        1.10.9
Release:        1%{?dist}
Summary:        Serialize the output of command line tools and filetypes to structured JSON

License:        MIT
URL:            https://github.com/kellyjonbrazil/jc
Source0:        %{pypi_source}
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3dist(setuptools)
BuildRequires:  python3dist(pygments) >= 2.4.2
BuildRequires:  python3dist(ruamel.yaml) >= 0.15
BuildRequires:  python3dist(xmltodict) >= 0.12

%description
%{desc}

%package -n     python3-%{pypi_name}
Summary:        %{summary}

%description -n python3-%{pypi_name}
%{desc}

%prep
%autosetup -n %{pypi_name}-%{version}
rm -rf %{pypi_name}.egg-info

%build
%py3_build

%install
%py3_install

%files -n python3-%{pypi_name}
%doc README.md
%license LICENSE.md
%{_bindir}/jc
%{python3_sitelib}/%{pypi_name}
%{python3_sitelib}/%{pypi_name}-%{version}-py%{python3_version}.egg-info

%changelog
* Fri May 08 2020 Kelly Brazil <kellyjonbrazil@gmail.com> - 1.10.9-1
- Initial package.
