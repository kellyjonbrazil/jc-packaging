# Created by pyp2rpm-3.3.4
%global pypi_name jc

Name:           python-%{pypi_name}
Version:        1.10.7
Release:        1%{?dist}
Summary:        This tool serializes the output of popular command line tools and filetypes to structured JSON output

License:        MIT
URL:            https://github.com/kellyjonbrazil/jc
Source0:        %{pypi_source}
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3dist(pygments) >= 2.4.2
BuildRequires:  python3dist(ruamel.yaml) >= 0.15
BuildRequires:  python3dist(setuptools)
BuildRequires:  python3dist(xmltodict) >= 0.12

%description
JSON CLI output utility. jc is used to JSONify the output of many standard linux
cli tools and file types for easier parsing in scripts.

%package -n     python3-%{pypi_name}
Summary:        %{summary}
%{?python_provide:%python_provide python3-%{pypi_name}}

Requires:       python3dist(pygments) >= 2.4.2
Requires:       python3dist(ruamel.yaml) >= 0.15
Requires:       python3dist(setuptools)
Requires:       python3dist(xmltodict) >= 0.12
%description -n python3-%{pypi_name}
JSON CLI output utility. jc is used to JSONify the output of many standard linux
cli tools and file types for easier parsing in scripts.


%prep
%autosetup -n %{pypi_name}-%{version}
# Remove bundled egg-info
rm -rf %{pypi_name}.egg-info

%build
%py3_build

%install
%py3_install

%check
%{__python3} setup.py test

%files -n python3-%{pypi_name}
%doc README.md
%{_bindir}/jc
%{python3_sitelib}/%{pypi_name}
%{python3_sitelib}/tests
%{python3_sitelib}/%{pypi_name}-%{version}-py%{python3_version}.egg-info

%changelog
* Fri May 01 2020 kbrazil - 1.10.7-1
- Initial package.

